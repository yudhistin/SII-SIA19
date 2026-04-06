-- ============================================================
-- AM: Federated Integration View -- toate 4 surse
-- SII-SIA19: Retail Sales Federated Analysis System
-- V_INTEGRATED_SALES: DS1 + DS2 + DS3 + DS4
-- ============================================================
 
CREATE OR REPLACE VIEW FDBO.V_INTEGRATED_SALES AS
-- DS1: Oracle External Table -- Retail Sales (1000 rows)
SELECT
    'DS1_Oracle'        AS SOURCE_DB,
    CUSTOMER_ID,
    GENDER,
    AGE,
    PRODUCT_CATEGORY    AS CATEGORY,
    QUANTITY,
    PRICE_PER_UNIT      AS PRICE,
    TOTAL_AMOUNT
FROM FDBO.V_RETAIL_SALES
UNION ALL
-- DS2: PostgreSQL via PostgREST REST API (1000 sample rows)
SELECT
    'DS2_PostgreSQL'    AS SOURCE_DB,
    CUSTOMER_ID,
    GENDER,
    AGE,
    CATEGORY,
    QUANTITY,
    PRICE,
    QUANTITY * PRICE    AS TOTAL_AMOUNT
FROM FDBO.V_SHOPPING_DATA
UNION ALL
-- DS3: CSV via Oracle External Table (2823 rows)
SELECT
    'DS3_CSV'           AS SOURCE_DB,
    CUSTOMER_NAME       AS CUSTOMER_ID,
    NULL                AS GENDER,
    NULL                AS AGE,
    PRODUCT_LINE        AS CATEGORY,
    QTY_ORDERED         AS QUANTITY,
    PRICE_EACH          AS PRICE,
    SALES               AS TOTAL_AMOUNT
FROM FDBO.V_SALES_SAMPLE
UNION ALL
-- DS4: MongoDB via JSON export + GET_JSON_FILE() (1000 sample docs)
SELECT
    'DS4_MongoDB'       AS SOURCE_DB,
    INVOICE             AS CUSTOMER_ID,
    NULL                AS GENDER,
    NULL                AS AGE,
    DESCRIPTION         AS CATEGORY,
    QUANTITY,
    PRICE,
    QUANTITY * PRICE    AS TOTAL_AMOUNT
FROM FDBO.V_ONLINE_RETAIL;
 
-- Test: distributie pe surse
SELECT SOURCE_DB, COUNT(*) NR_TRANZACTII, ROUND(SUM(TOTAL_AMOUNT),2) TOTAL_VANZARI
FROM FDBO.V_INTEGRATED_SALES
GROUP BY SOURCE_DB
ORDER BY TOTAL_VANZARI DESC;
-- Expected:
-- DS3_CSV          2823   10032628.90
-- DS2_PostgreSQL   1000    2490432.92
-- DS1_Oracle       1000     456000.00
-- DS4_MongoDB      1000      18039.48
 
-- Test: top 10 categorii
SELECT CATEGORY, COUNT(*) NR, ROUND(SUM(TOTAL_AMOUNT),2) TOTAL
FROM FDBO.V_INTEGRATED_SALES
WHERE CATEGORY IS NOT NULL
GROUP BY CATEGORY
ORDER BY TOTAL DESC
FETCH FIRST 10 ROWS ONLY;
 
-- Test: distributie gender (DS1 + DS2)
SELECT GENDER, COUNT(*) NR
FROM FDBO.V_INTEGRATED_SALES
WHERE GENDER IS NOT NULL
GROUP BY GENDER;
-- Expected: Female 1122, Male 878