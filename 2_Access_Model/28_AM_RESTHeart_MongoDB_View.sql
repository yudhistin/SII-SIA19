-- ============================================================
-- AM (DS3): MongoDB Access via RESTHeart + UTL_HTTP + JSON_TABLE
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Federation pattern (per course material C2.FDB_ORCL.Data_Source_Access4_NoSQL):
--   MongoDB  --(RESTHeart)-->  HTTP/JSON  --(UTL_HTTP+Basic Auth)-->  Oracle CLOB
--   --(JSON_TABLE)-->  SQL access view
--
-- Endpoint assumptions:
--   RESTHeart is running locally and exposes MongoDB:
--     java -jar restheart.jar -o conf-override.conf
--   Listening on:  http://host.docker.internal:8080
--   Mount:         /realestate/forsale  (collection realestate.forsale)
-- ============================================================

-- Disable substitution-variable prompting (URL contains '?' and '&')
SET DEFINE OFF;

-- ---------- Pas 1: ACL access for FDBO -> RESTHeart host ----------
-- Run as SYS once (skip if already granted by 26_AM_POSTGREST_Rentals_View.sql):
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'host.docker.internal',
        ace  => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'FDBO',
            principal_type => xs_acl.ptype_db
        )
    );
END;
/

-- ---------- Pas 2: HTTP-fetch helper with Basic Auth ----------
-- Mirrors the course pattern: get_restheart_data_media(URL, USER:PASS)
CREATE OR REPLACE FUNCTION FDBO.GET_RESTHEART_DATA(
    p_url        VARCHAR2,
    p_user_pass  VARCHAR2
) RETURN CLOB IS
    v_req     UTL_HTTP.REQ;
    v_resp    UTL_HTTP.RESP;
    v_buffer  VARCHAR2(32767);
    v_clob    CLOB := '';
BEGIN
    UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
    v_req := UTL_HTTP.BEGIN_REQUEST(p_url);
    UTL_HTTP.SET_HEADER(
        v_req,
        'Authorization',
        'Basic ' || UTL_RAW.CAST_TO_VARCHAR2(
            UTL_ENCODE.BASE64_ENCODE(
                UTL_I18N.STRING_TO_RAW(p_user_pass, 'AL32UTF8')
            )
        )
    );
    UTL_HTTP.SET_HEADER(v_req, 'Accept', 'application/json');
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);
    LOOP
        BEGIN
            UTL_HTTP.READ_TEXT(v_resp, v_buffer, 32767);
            v_clob := v_clob || v_buffer;
        EXCEPTION WHEN UTL_HTTP.END_OF_BODY THEN EXIT;
        END;
    END LOOP;
    UTL_HTTP.END_RESPONSE(v_resp);
    RETURN v_clob;
END;
/

-- ---------- Pas 3: Remote MongoDB collection view ----------
-- Note: RESTHeart returns the collection as a JSON array of docs.
-- rep=s         -> Standard representation (plain JSON array, not HAL-wrapped)
-- pagesize=1000 -> RESTHeart's per-request cap; for >1000 docs, page through
CREATE OR REPLACE VIEW FDBO.V_REALTOR_FORSALE AS
WITH json_doc AS (
    SELECT FDBO.GET_RESTHEART_DATA(
        'http://host.docker.internal:8080/realestate/forsale?pagesize=1000&rep=s&filter={"status":"for_sale"}',
        'admin:secret'
    ) doc FROM dual
)
SELECT *
FROM JSON_TABLE(
    (SELECT doc FROM json_doc),
    '$[*]' COLUMNS (
        BROKERED_BY      NUMBER         PATH '$.brokered_by',
        STATUS           VARCHAR2(20)   PATH '$.status',
        PRICE            NUMBER         PATH '$.price',
        BED              NUMBER         PATH '$.bed',
        BATH             NUMBER         PATH '$.bath',
        ACRE_LOT         NUMBER         PATH '$.acre_lot',
        STREET           NUMBER         PATH '$.street',
        CITY             VARCHAR2(80)   PATH '$.city',
        STATE            VARCHAR2(40)   PATH '$.state',
        ZIP_CODE         VARCHAR2(10)   PATH '$.zip_code',
        HOUSE_SIZE       NUMBER         PATH '$.house_size',
        PREV_SOLD_DATE   VARCHAR2(20)   PATH '$.prev_sold_date'
    )
);

COMMENT ON TABLE FDBO.V_REALTOR_FORSALE IS
    'DS3 access view - Realtor.com for-sale listings via RESTHeart';

-- ---------- VERIFICATION ----------
SELECT COUNT(*) FROM FDBO.V_REALTOR_FORSALE;

SELECT STATE, COUNT(*) NR_LISTINGS,
       ROUND(AVG(PRICE), 0) AVG_PRICE,
       ROUND(AVG(HOUSE_SIZE), 0) AVG_SIZE
FROM FDBO.V_REALTOR_FORSALE
WHERE PRICE > 0 AND HOUSE_SIZE > 0
GROUP BY STATE
ORDER BY NR_LISTINGS DESC
FETCH FIRST 15 ROWS ONLY;

-- Top 10 brokers by inventory
SELECT BROKERED_BY, COUNT(*) NR_LISTINGS,
       ROUND(SUM(PRICE)/1e6, 1) TOTAL_M_USD
FROM FDBO.V_REALTOR_FORSALE
WHERE BROKERED_BY IS NOT NULL
GROUP BY BROKERED_BY
ORDER BY NR_LISTINGS DESC
FETCH FIRST 10 ROWS ONLY;
