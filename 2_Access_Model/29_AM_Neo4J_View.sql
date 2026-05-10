-- ============================================================
-- AM (DS4): Neo4j Access via Query API + UTL_HTTP POST + JSON_TABLE
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Federation pattern (per course material C2.FDB_ORCL.Data_Source_Access4_NoSQL):
--   Neo4j  --(Query API v2)-->  HTTP POST/JSON  --(UTL_HTTP+Basic Auth)-->  Oracle CLOB
--   --(JSON_TABLE)-->  SQL access view
--
-- Endpoint assumptions:
--   Neo4j Community 5.x running locally with default Query API enabled.
--   Endpoint:    http://host.docker.internal:7474/db/neo4j/query/v2
--   Credentials: neo4j / neo4j_admin   (change to whatever you set)
-- ============================================================

-- ---------- Pas 1: ACL access (skip if granted earlier) ----------
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

-- ---------- Pas 2: HTTP POST helper for Cypher queries ----------
CREATE OR REPLACE FUNCTION FDBO.QUERY_NEO4J(
    p_rest_url       VARCHAR2,
    p_cypher_query   VARCHAR2,
    p_user_name      VARCHAR2,
    p_pass           VARCHAR2
) RETURN CLOB IS
    v_req       UTL_HTTP.REQ;
    v_resp      UTL_HTTP.RESP;
    v_buffer    VARCHAR2(32767);
    v_clob      CLOB := '';
    v_userpass  VARCHAR2(2000) := p_user_name || ':' || p_pass;
    v_body      VARCHAR2(4000);
BEGIN
    -- Neo4j Query API v2 expects: { "statement": "<cypher>" }
    v_body := REPLACE('{ "statement": "$statement" }',
                      '$statement',
                      REPLACE(p_cypher_query, '"', '\"'));

    UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
    v_req := UTL_HTTP.BEGIN_REQUEST(p_rest_url, 'POST');
    UTL_HTTP.SET_HEADER(v_req, 'Content-Type',   'application/json');
    UTL_HTTP.SET_HEADER(v_req, 'Accept',         'application/json');
    UTL_HTTP.SET_HEADER(v_req, 'Content-Length', LENGTH(v_body));
    UTL_HTTP.SET_HEADER(
        v_req,
        'Authorization',
        'Basic ' || UTL_RAW.CAST_TO_VARCHAR2(
            UTL_ENCODE.BASE64_ENCODE(
                UTL_I18N.STRING_TO_RAW(v_userpass, 'AL32UTF8')
            )
        )
    );
    UTL_HTTP.SET_BODY_CHARSET(v_req, 'UTF-8');
    UTL_HTTP.WRITE_TEXT(v_req, v_body);

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

-- ---------- Pas 3: Remote Neo4j graph view ----------
-- Returns the full Country -> Region -> City -> Neighborhood hierarchy as a
-- flat relational dimension. Mirrors the course's $.data.values[*] pattern.
CREATE OR REPLACE VIEW FDBO.V_GEO_HIERARCHY AS
WITH json_doc AS (
    SELECT FDBO.QUERY_NEO4J(
        'http://host.docker.internal:7474/db/neo4j/query/v2',
        'MATCH (nh:Neighborhood)-[:PART_OF]->(ci:City)-[:PART_OF]->(rg:Region)-[:PART_OF]->(co:Country) '
        || 'RETURN co.code, co.name, rg.code, rg.name, ci.id, ci.name, nh.id, nh.name',
        'neo4j', 'neo4j_admin'
    ) doc FROM dual
)
SELECT *
FROM JSON_TABLE(
    (SELECT doc FROM json_doc),
    '$.data.values[*]'
    COLUMNS (
        COUNTRY_CODE      VARCHAR2(4)    PATH '$[0]' NULL ON ERROR,
        COUNTRY_NAME      VARCHAR2(60)   PATH '$[1]' NULL ON ERROR,
        REGION_CODE       VARCHAR2(10)   PATH '$[2]' NULL ON ERROR,
        REGION_NAME       VARCHAR2(60)   PATH '$[3]' NULL ON ERROR,
        CITY_ID           VARCHAR2(20)   PATH '$[4]' NULL ON ERROR,
        CITY_NAME         VARCHAR2(60)   PATH '$[5]' NULL ON ERROR,
        NEIGHBORHOOD_ID   VARCHAR2(30)   PATH '$[6]' NULL ON ERROR,
        NEIGHBORHOOD_NAME VARCHAR2(80)   PATH '$[7]' NULL ON ERROR
    )
);

COMMENT ON TABLE FDBO.V_GEO_HIERARCHY IS
    'DS4 access view - geographic hierarchy via Neo4j Query API';

-- ---------- VERIFICATION ----------
SELECT COUNT(*) NR_LEAVES FROM FDBO.V_GEO_HIERARCHY;

SELECT COUNTRY_CODE, COUNT(DISTINCT REGION_CODE) NR_REGIONS,
       COUNT(DISTINCT CITY_ID) NR_CITIES,
       COUNT(NEIGHBORHOOD_ID)  NR_NEIGHBORHOODS
FROM FDBO.V_GEO_HIERARCHY
GROUP BY COUNTRY_CODE
ORDER BY COUNTRY_CODE;

-- Cities currently mapped in the geo dim (for cross-source joins)
SELECT DISTINCT COUNTRY_CODE, REGION_CODE, CITY_NAME
FROM FDBO.V_GEO_HIERARCHY
ORDER BY COUNTRY_CODE, REGION_CODE, CITY_NAME;
