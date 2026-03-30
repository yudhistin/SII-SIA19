-- =============================================================
-- P4. REST Web Services Definitions
-- SIA19: Integrated Real Estate Market Analysis System
-- FDBO Schema - Web Model
-- =============================================================

-- -------------------------------------------------------------
-- SERVICE 1: PostgREST REST API over PostgreSQL
-- URL: http://host.docker.internal:3000
-- Auth: none (web_anon role)
-- -------------------------------------------------------------

-- Endpoint: GET /customers (10 records)
CREATE OR REPLACE VIEW WEB_REST_CUSTOMERS AS
SELECT jt.*
FROM JSON_TABLE(
    UTL_HTTP.REQUEST('http://host.docker.internal:3000/customers'),
    '$[*]' COLUMNS (
        CUSTOMER_ID       NUMBER        PATH '$.customer_id',
        FIRST_NAME        VARCHAR2(50)  PATH '$.first_name',
        LAST_NAME         VARCHAR2(50)  PATH '$.last_name',
        EMAIL             VARCHAR2(100) PATH '$.email',
        PHONE             VARCHAR2(20)  PATH '$.phone',
        CITY_ID           NUMBER        PATH '$.city_id',
        CATEGORY_ID       NUMBER        PATH '$.category_id',
        REGISTRATION_DATE VARCHAR2(20)  PATH '$.registration_date'
    )
) jt;

-- Endpoint: GET /cities (8 records)
CREATE OR REPLACE VIEW WEB_REST_CITIES AS
SELECT jt.*
FROM JSON_TABLE(
    UTL_HTTP.REQUEST('http://host.docker.internal:3000/cities'),
    '$[*]' COLUMNS (
        CITY_ID       NUMBER        PATH '$.city_id',
        CITY_NAME     VARCHAR2(100) PATH '$.city_name',
        POSTAL_CODE   VARCHAR2(10)  PATH '$.postal_code',
        DEPARTMENT_ID NUMBER        PATH '$.department_id',
        COUNTRY_NAME  VARCHAR2(50)  PATH '$.country_name'
    )
) jt;

-- Endpoint: GET /customer_categories (4 records)
CREATE OR REPLACE VIEW WEB_REST_CATEGORIES AS
SELECT jt.*
FROM JSON_TABLE(
    UTL_HTTP.REQUEST('http://host.docker.internal:3000/customer_categories'),
    '$[*]' COLUMNS (
        CATEGORY_ID   NUMBER        PATH '$.category_id',
        CATEGORY_NAME VARCHAR2(50)  PATH '$.category_name',
        DISCOUNT_PCT  NUMBER        PATH '$.discount_pct'
    )
) jt;

-- -------------------------------------------------------------
-- SERVICE 2: Neo4j Query REST API v2
-- URL: http://host.docker.internal:7474/db/neo4j/query/v2
-- Auth: Basic neo4j:neo4j_admin
-- Method: POST
-- -------------------------------------------------------------

-- Endpoint: MATCH City-LOCATED_IN-Departament (8 records)
CREATE OR REPLACE VIEW WEB_NEO4J_CITY_DEPT AS
SELECT jt.*
FROM JSON_TABLE(
    GET_NEO4J_DATA('MATCH (c:City) -[r:LOCATED_IN]-> (d:Departament) RETURN c.idCity, c.cityName, c.postalCode, d.departamentName, d.countryName'),
    '$.data.values[*]' COLUMNS (
        CITY_ID         NUMBER        PATH '$[0]',
        CITY_NAME       VARCHAR2(100) PATH '$[1]',
        POSTAL_CODE     VARCHAR2(10)  PATH '$[2]',
        DEPARTMENT_NAME VARCHAR2(100) PATH '$[3]',
        COUNTRY_NAME    VARCHAR2(50)  PATH '$[4]'
    )
) jt;

-- -------------------------------------------------------------
-- TEST ALL REST ENDPOINTS
-- -------------------------------------------------------------
SELECT 'PostgREST /customers' AS endpoint, COUNT(*) AS records FROM WEB_REST_CUSTOMERS
UNION ALL
SELECT 'PostgREST /cities',         COUNT(*) FROM WEB_REST_CITIES
UNION ALL
SELECT 'PostgREST /categories',     COUNT(*) FROM WEB_REST_CATEGORIES
UNION ALL
SELECT 'Neo4j /query/v2',           COUNT(*) FROM WEB_NEO4J_CITY_DEPT;
