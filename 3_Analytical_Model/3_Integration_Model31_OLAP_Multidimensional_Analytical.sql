-- ============================================================
-- Integration Model: OLAP Analytical Views
-- SII-SIA19: Retail Sales Federated Analysis System
-- Sursa: V_INTEGRATED_SALES (DS1 + DS2 + DS3 + DS4)
-- ============================================================
 
-- ============================================================
-- 1. ROLLUP: Vanzari pe sursa si categorie (ierarhie 2 nivele)
-- ============================================================
CREATE OR REPLACE VIEW FDBO.OLAP_VIEW_SALES_SOURCE_CATEGORY AS
SELECT
    SOURCE_DB,
    CATEGORY,
    COUNT(*)                        AS NR_TRANZACTII,
    ROUND(SUM(TOTAL_AMOUNT), 2)    AS TOTAL_VANZARI,
    ROUND(AVG(PRICE), 2)           AS AVG_PRICE,
    GROUPING(SOURCE_DB)            AS GRP_SOURCE,
    GROUPING(CATEGORY)             AS GRP_CATEGORY
FROM FDBO.V_INTEGRATED_SALES
WHERE CATEGORY IS NOT NULL
GROUP BY ROLLUP(SOURCE_DB, CATEGORY)
ORDER BY SOURCE_DB NULLS LAST, TOTAL_VANZARI DESC NULLS LAST;
 
-- Test ROLLUP
SELECT * FROM FDBO.OLAP_VIEW_SALES_SOURCE_CATEGORY
WHERE GRP_SOURCE = 0 AND GRP_CATEGORY = 1; -- Subtotaluri per sursa
 
-- ============================================================
-- 2. ROLLUP: Analiza temporala (nu avem date calendaristice uniforme,
--    folosim SOURCE_DB ca dimensiune principala + GENDER)
-- ============================================================
CREATE OR REPLACE VIEW FDBO.OLAP_VIEW_SALES_GENDER_SOURCE AS
SELECT
    SOURCE_DB,
    GENDER,
    COUNT(*)                        AS NR_TRANZACTII,
    ROUND(SUM(TOTAL_AMOUNT), 2)    AS TOTAL_VANZARI,
    ROUND(AVG(AGE), 1)             AS AVG_AGE,
    GROUPING(SOURCE_DB)            AS GRP_SOURCE,
    GROUPING(GENDER)               AS GRP_GENDER
FROM FDBO.V_INTEGRATED_SALES
WHERE GENDER IS NOT NULL
GROUP BY ROLLUP(SOURCE_DB, GENDER)
ORDER BY SOURCE_DB NULLS LAST, GENDER NULLS LAST;
 
-- Test ROLLUP gender
SELECT SOURCE_DB, GENDER, NR_TRANZACTII, TOTAL_VANZARI
FROM FDBO.OLAP_VIEW_SALES_GENDER_SOURCE
WHERE GRP_SOURCE = 0 AND GRP_GENDER = 0;
 
-- ============================================================
-- 3. CUBE: Cross-tabulation sursa x categorie
-- ============================================================
CREATE OR REPLACE VIEW FDBO.OLAP_VIEW_CUBE_SOURCE_CATEGORY AS
SELECT
    SOURCE_DB,
    CATEGORY,
    COUNT(*)                        AS NR_TRANZACTII,
    ROUND(SUM(TOTAL_AMOUNT), 2)    AS TOTAL_VANZARI,
    GROUPING(SOURCE_DB)            AS GRP_SOURCE,
    GROUPING(CATEGORY)             AS GRP_CATEGORY
FROM FDBO.V_INTEGRATED_SALES
WHERE CATEGORY IS NOT NULL
GROUP BY CUBE(SOURCE_DB, CATEGORY)
ORDER BY SOURCE_DB NULLS LAST, TOTAL_VANZARI DESC NULLS LAST;
 
-- Test CUBE: grand total
SELECT NR_TRANZACTII, TOTAL_VANZARI
FROM FDBO.OLAP_VIEW_CUBE_SOURCE_CATEGORY
WHERE GRP_SOURCE = 1 AND GRP_CATEGORY = 1;
-- Expected: 5823 tranzactii
 
-- ============================================================
-- 4. GROUPING SETS: Agregari custom
-- ============================================================
CREATE OR REPLACE VIEW FDBO.OLAP_VIEW_GROUPING_SETS AS
SELECT
    SOURCE_DB,
    CATEGORY,
    GENDER,
    COUNT(*)                        AS NR_TRANZACTII,
    ROUND(SUM(TOTAL_AMOUNT), 2)    AS TOTAL_VANZARI,
    GROUPING(SOURCE_DB)            AS GRP_SOURCE,
    GROUPING(CATEGORY)             AS GRP_CATEGORY,
    GROUPING(GENDER)               AS GRP_GENDER
FROM FDBO.V_INTEGRATED_SALES
GROUP BY GROUPING SETS (
    (SOURCE_DB, CATEGORY),   -- detaliu: sursa + categorie
    (SOURCE_DB, GENDER),     -- detaliu: sursa + gender
    (SOURCE_DB),             -- subtotal per sursa
    ()                       -- grand total
)
ORDER BY GRP_SOURCE, GRP_CATEGORY, GRP_GENDER, TOTAL_VANZARI DESC NULLS LAST;
 
-- Test GROUPING SETS: grand total
SELECT NR_TRANZACTII, TOTAL_VANZARI
FROM FDBO.OLAP_VIEW_GROUPING_SETS
WHERE GRP_SOURCE = 1 AND GRP_CATEGORY = 1 AND GRP_GENDER = 1;
-- Expected total: ~12997099
 
-- ============================================================
-- 5. Verificare finala: distributie completa
-- ============================================================
SELECT SOURCE_DB,
       COUNT(*)                     AS NR_TRANZACTII,
       ROUND(SUM(TOTAL_AMOUNT), 2) AS TOTAL_VANZARI,
       ROUND(AVG(PRICE), 2)        AS AVG_PRICE,
       MIN(QUANTITY)               AS MIN_QTY,
       MAX(QUANTITY)               AS MAX_QTY
FROM FDBO.V_INTEGRATED_SALES
GROUP BY SOURCE_DB
ORDER BY TOTAL_VANZARI DESC;