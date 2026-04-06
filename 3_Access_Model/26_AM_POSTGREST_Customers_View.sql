-- ============================================================
-- AM: PostgreSQL Access via PostgREST REST API
-- SII-SIA19: Retail Sales Federated Analysis System
-- Dataset: customer_shopping_data.csv (99457 rows)
-- PostgREST endpoint: http://host.docker.internal:3000/shopping_data
-- ============================================================
 
-- Pas 1: Acord acces retea Oracle -> PostgREST (ruleaza ca SYS)
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
 
-- Pas 2: Functia PL/SQL care apeleaza PostgREST via UTL_HTTP
CREATE OR REPLACE FUNCTION FDBO.GET_PG_SHOPPING(p_limit NUMBER DEFAULT 1000)
RETURN CLOB AS
    v_url     VARCHAR2(500);
    v_req     UTL_HTTP.REQ;
    v_resp    UTL_HTTP.RESP;
    v_buffer  VARCHAR2(32767);
    v_clob    CLOB := '';
BEGIN
    v_url := 'http://host.docker.internal:3000/shopping_data?limit=' || p_limit;
    UTL_HTTP.SET_TRANSFER_TIMEOUT(60);
    v_req  := UTL_HTTP.BEGIN_REQUEST(v_url);
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
 
-- Pas 3: View DS2 -- parseaza JSON array din PostgREST
CREATE OR REPLACE VIEW FDBO.V_SHOPPING_DATA AS
SELECT *
FROM JSON_TABLE(
    FDBO.GET_PG_SHOPPING(1000),
    '$[*]' COLUMNS (
        INVOICE_NO      VARCHAR2(20)  PATH '$.invoice_no',
        CUSTOMER_ID     VARCHAR2(20)  PATH '$.customer_id',
        GENDER          VARCHAR2(10)  PATH '$.gender',
        AGE             NUMBER        PATH '$.age',
        CATEGORY        VARCHAR2(50)  PATH '$.category',
        QUANTITY        NUMBER        PATH '$.quantity',
        PRICE           NUMBER        PATH '$.price',
        PAYMENT_METHOD  VARCHAR2(30)  PATH '$.payment_method',
        INVOICE_DATE    VARCHAR2(20)  PATH '$.invoice_date',
        SHOPPING_MALL   VARCHAR2(50)  PATH '$.shopping_mall'
    )
);
 
-- Test
SELECT COUNT(*) FROM FDBO.V_SHOPPING_DATA;
-- Expected: 1000
 
SELECT CATEGORY, COUNT(*) NR, ROUND(SUM(PRICE * QUANTITY), 2) TOTAL
FROM FDBO.V_SHOPPING_DATA
GROUP BY CATEGORY
ORDER BY TOTAL DESC;
 
