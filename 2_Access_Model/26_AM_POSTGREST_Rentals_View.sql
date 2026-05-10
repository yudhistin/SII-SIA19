-- ============================================================
-- AM (DS2): PostgreSQL Access via PostgREST + UTL_HTTP + JSON_TABLE
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Federation pattern (per course material C2.FDB_ORCL.Data_Source_Access1*):
--   PostgreSQL  --(PostgREST)-->  HTTP/JSON  --(UTL_HTTP)-->  Oracle CLOB
--   --(JSON_TABLE)-->  SQL access view
--
-- Endpoint assumptions:
--   PostgREST is running locally and exposes the `rentals` schema.
--     postgrest postgrest.conf
--   Listening on:  http://host.docker.internal:3000
--   Tables:        /listing  and  /host
-- ============================================================

-- ---------- Pas 1: ACL access for FDBO -> PostgREST host ----------
-- Run as SYS (one-off):
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
-- Repeat with host => 'localhost' if PostgREST is bound to localhost.

-- ---------- Pas 2: HTTP-fetch helper (JSON CLOB) ----------
CREATE OR REPLACE FUNCTION FDBO.GET_PG_LISTINGS(p_limit NUMBER DEFAULT 5000)
RETURN CLOB AS
    v_url     VARCHAR2(500);
    v_req     UTL_HTTP.REQ;
    v_resp    UTL_HTTP.RESP;
    v_buffer  VARCHAR2(32767);
    v_clob    CLOB := '';
BEGIN
    v_url := 'http://host.docker.internal:3000/listing?limit=' || p_limit;
    UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
    v_req  := UTL_HTTP.BEGIN_REQUEST(v_url);
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

CREATE OR REPLACE FUNCTION FDBO.GET_PG_HOSTS(p_limit NUMBER DEFAULT 5000)
RETURN CLOB AS
    v_url     VARCHAR2(500);
    v_req     UTL_HTTP.REQ;
    v_resp    UTL_HTTP.RESP;
    v_buffer  VARCHAR2(32767);
    v_clob    CLOB := '';
BEGIN
    v_url := 'http://host.docker.internal:3000/host?limit=' || p_limit;
    UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
    v_req  := UTL_HTTP.BEGIN_REQUEST(v_url);
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

-- ---------- Pas 3: Remote JSON views (model matching) ----------
CREATE OR REPLACE VIEW FDBO.V_AIRBNB_LISTINGS AS
SELECT *
FROM JSON_TABLE(
    FDBO.GET_PG_LISTINGS(5000),
    '$[*]' COLUMNS (
        LISTING_ID             NUMBER         PATH '$.listing_id',
        HOST_ID                NUMBER         PATH '$.host_id',
        NAME                   VARCHAR2(300)  PATH '$.name',
        NEIGHBOURHOOD          VARCHAR2(150)  PATH '$.neighbourhood_cleansed',
        CITY                   VARCHAR2(80)   PATH '$.city',
        LATITUDE               NUMBER         PATH '$.latitude',
        LONGITUDE              NUMBER         PATH '$.longitude',
        PROPERTY_TYPE          VARCHAR2(80)   PATH '$.property_type',
        ROOM_TYPE              VARCHAR2(40)   PATH '$.room_type',
        ACCOMMODATES           NUMBER         PATH '$.accommodates',
        BATHROOMS              NUMBER         PATH '$.bathrooms',
        BEDROOMS               NUMBER         PATH '$.bedrooms',
        BEDS                   NUMBER         PATH '$.beds',
        PRICE                  NUMBER         PATH '$.price',
        MINIMUM_NIGHTS         NUMBER         PATH '$.minimum_nights',
        AVAILABILITY_365       NUMBER         PATH '$.availability_365',
        NUMBER_OF_REVIEWS      NUMBER         PATH '$.number_of_reviews',
        REVIEW_SCORES_RATING   NUMBER         PATH '$.review_scores_rating',
        LAST_SCRAPED           VARCHAR2(20)   PATH '$.last_scraped'
    )
);

CREATE OR REPLACE VIEW FDBO.V_AIRBNB_HOSTS AS
SELECT *
FROM JSON_TABLE(
    FDBO.GET_PG_HOSTS(5000),
    '$[*]' COLUMNS (
        HOST_ID                  NUMBER         PATH '$.host_id',
        HOST_NAME                VARCHAR2(150)  PATH '$.host_name',
        HOST_SINCE               VARCHAR2(20)   PATH '$.host_since',
        HOST_LOCATION            VARCHAR2(200)  PATH '$.host_location',
        HOST_RESPONSE_RATE       VARCHAR2(10)   PATH '$.host_response_rate',
        HOST_ACCEPTANCE_RATE     VARCHAR2(10)   PATH '$.host_acceptance_rate',
        HOST_IS_SUPERHOST        VARCHAR2(5)    PATH '$.host_is_superhost',
        HOST_LISTINGS_COUNT      NUMBER         PATH '$.host_listings_count',
        HOST_IDENTITY_VERIFIED   VARCHAR2(5)    PATH '$.host_identity_verified'
    )
);

-- ---------- VERIFICATION ----------
SELECT COUNT(*) FROM FDBO.V_AIRBNB_LISTINGS;
SELECT COUNT(*) FROM FDBO.V_AIRBNB_HOSTS;

SELECT NEIGHBOURHOOD, ROOM_TYPE, COUNT(*) NR,
       ROUND(AVG(PRICE), 2) AVG_PRICE,
       ROUND(AVG(REVIEW_SCORES_RATING), 2) AVG_RATING
FROM FDBO.V_AIRBNB_LISTINGS
GROUP BY NEIGHBOURHOOD, ROOM_TYPE
ORDER BY NR DESC
FETCH FIRST 15 ROWS ONLY;

SELECT HOST_IS_SUPERHOST, COUNT(*) NR_HOSTS,
       ROUND(AVG(HOST_LISTINGS_COUNT), 1) AVG_LISTINGS
FROM FDBO.V_AIRBNB_HOSTS
GROUP BY HOST_IS_SUPERHOST;
