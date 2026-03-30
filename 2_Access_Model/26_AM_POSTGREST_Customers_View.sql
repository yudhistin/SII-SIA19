 -- AM: PostgreSQL Customers View via PostgREST REST API
-- FDBO schema - Access Model

CREATE OR REPLACE VIEW FDBO.AM_POSTGREST_CUSTOMERS_VIEW AS
WITH response AS (
    SELECT UTL_HTTP.REQUEST('http://host.docker.internal:3000/customers') AS json_data
    FROM DUAL
)
SELECT 
    jt.CUSTOMER_ID, jt.FIRST_NAME, jt.LAST_NAME,
    jt.EMAIL, jt.PHONE, jt.CITY_ID,
    jt.CATEGORY_ID, jt.REGISTRATION_DATE
FROM response,
JSON_TABLE(response.json_data, '$[*]'
    COLUMNS (
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
