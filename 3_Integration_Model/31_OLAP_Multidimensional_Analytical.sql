-- ============================================================
-- Integration Model: OLAP Analytical Views
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Inputs (built by 2_Access_Model/):
--   FDBO.V_NYC_SALES              (DS1 - sold transactions)
--   FDBO.V_AIRBNB_LISTINGS        (DS2 - rental listings)
--   FDBO.V_AIRBNB_HOSTS           (DS2 - hosts / agents)
--   FDBO.V_REALTOR_FORSALE        (DS3 - for-sale listings)
--   FDBO.V_GEO_HIERARCHY          (DS4 - geographic dim)
--   FDBO.V_MACRO_INDICATORS       (DS5 - monthly macro)
--   FDBO.V_FEDERATED_PROPERTIES   (consolidated 1+2+3)
--
-- Output: a Kimball star with three fact views + four conformed
-- dimensions, and a set of analytical (multidimensional) views
-- ready to drive the REST/WEB layer.
-- ============================================================


-- ============================================================
-- 1) CONFORMED DIMENSIONS
-- ============================================================

-- 1.1 D_TIME - month-grain time dimension derived from MACRO + facts
CREATE OR REPLACE VIEW FDBO.D_TIME AS
SELECT DISTINCT
    PERIOD_DATE              AS DATE_KEY,
    YEAR_NO,
    QUARTER_NO,
    MONTH_NO,
    TO_CHAR(PERIOD_DATE, 'YYYY-MM')  AS YEAR_MONTH,
    TO_CHAR(PERIOD_DATE, 'YYYY-"Q"Q') AS YEAR_QUARTER
FROM FDBO.V_MACRO_INDICATORS;

-- 1.2 D_GEO - flat geographic hierarchy from Neo4j
CREATE OR REPLACE VIEW FDBO.D_GEO AS
SELECT
    NEIGHBORHOOD_ID  AS GEO_KEY,
    COUNTRY_CODE,
    COUNTRY_NAME,
    REGION_CODE,
    REGION_NAME,
    CITY_ID,
    CITY_NAME,
    NEIGHBORHOOD_NAME
FROM FDBO.V_GEO_HIERARCHY;

-- 1.3 D_AGENT - hosts (DS2) + brokers (DS3) unified
CREATE OR REPLACE VIEW FDBO.D_AGENT AS
SELECT
    'HOST_' || TO_CHAR(HOST_ID)  AS AGENT_KEY,
    'HOST'                       AS AGENT_TYPE,
    HOST_NAME                    AS AGENT_NAME,
    HOST_LOCATION                AS AGENT_LOCATION,
    HOST_LISTINGS_COUNT          AS NR_LISTINGS,
    CASE HOST_IS_SUPERHOST WHEN 'true' THEN 'Y' ELSE 'N' END AS IS_PREMIUM
FROM FDBO.V_AIRBNB_HOSTS
UNION ALL
SELECT DISTINCT
    'BROKER_' || TO_CHAR(BROKERED_BY)        AS AGENT_KEY,
    'BROKER'                                 AS AGENT_TYPE,
    'Broker #' || TO_CHAR(BROKERED_BY)       AS AGENT_NAME,
    NULL                                     AS AGENT_LOCATION,
    COUNT(*) OVER (PARTITION BY BROKERED_BY) AS NR_LISTINGS,
    'N'                                      AS IS_PREMIUM
FROM FDBO.V_REALTOR_FORSALE
WHERE BROKERED_BY IS NOT NULL;

-- 1.4 D_PROPERTY_TYPE - small role-playing dim
CREATE OR REPLACE VIEW FDBO.D_PROPERTY_TYPE AS
SELECT 'SOLD'     AS PROPERTY_TYPE_KEY, 'Sold transaction'   AS DESCRIPTION FROM dual UNION ALL
SELECT 'RENTAL'   AS PROPERTY_TYPE_KEY, 'Active rental'      AS DESCRIPTION FROM dual UNION ALL
SELECT 'FOR_SALE' AS PROPERTY_TYPE_KEY, 'Active for-sale'    AS DESCRIPTION FROM dual;


-- ============================================================
-- 2) FACT VIEWS  (one per measure family)
-- ============================================================

-- 2.1 F_SALES - NYC sold transactions
CREATE OR REPLACE VIEW FDBO.F_SALES AS
SELECT
    SALE_ID,
    BOROUGH_NAME                              AS CITY_NAME,
    NEIGHBORHOOD                              AS NEIGHBORHOOD_NAME,
    TRUNC(SALE_DATE, 'MM')                    AS DATE_KEY,
    SALE_PRICE                                AS PRICE_USD,
    GROSS_SQUARE_FEET                         AS AREA_SQFT,
    CASE WHEN GROSS_SQUARE_FEET > 0
         THEN SALE_PRICE / GROSS_SQUARE_FEET
         ELSE NULL END                        AS PRICE_PER_SQFT,
    RESIDENTIAL_UNITS,
    COMMERCIAL_UNITS,
    YEAR_BUILT
FROM FDBO.V_NYC_SALES;

-- 2.2 F_RENTALS - Amsterdam rental snapshot
CREATE OR REPLACE VIEW FDBO.F_RENTALS AS
SELECT
    LISTING_ID,
    'HOST_' || TO_CHAR(HOST_ID)               AS AGENT_KEY,
    CITY                                      AS CITY_NAME,
    NEIGHBOURHOOD                             AS NEIGHBORHOOD_NAME,
    TRUNC(TO_DATE(LAST_SCRAPED, 'YYYY-MM-DD'), 'MM') AS DATE_KEY,
    PRICE                                     AS NIGHTLY_PRICE_EUR,
    PRICE * FDBO.EUR_USD_RATE                 AS NIGHTLY_PRICE_USD,
    PRICE * FDBO.EUR_USD_RATE * 30            AS MONTHLY_PRICE_USD_EQ,
    ACCOMMODATES,
    BEDROOMS,
    BEDS,
    REVIEW_SCORES_RATING,
    AVAILABILITY_365,
    PROPERTY_TYPE,
    ROOM_TYPE
FROM FDBO.V_AIRBNB_LISTINGS;

-- 2.3 F_FORSALE - Realtor.com for-sale listings
CREATE OR REPLACE VIEW FDBO.F_FORSALE AS
SELECT
    ROWNUM                                    AS FORSALE_ID,
    'BROKER_' || TO_CHAR(BROKERED_BY)         AS AGENT_KEY,
    CITY                                      AS CITY_NAME,
    STATE                                     AS REGION_NAME,
    PRICE                                     AS PRICE_USD,
    HOUSE_SIZE                                AS AREA_SQFT,
    CASE WHEN HOUSE_SIZE > 0
         THEN PRICE / HOUSE_SIZE
         ELSE NULL END                        AS PRICE_PER_SQFT,
    BED                                       AS BEDROOMS,
    BATH                                      AS BATHROOMS,
    ACRE_LOT                                  AS LOT_ACRES,
    CASE WHEN PREV_SOLD_DATE IS NOT NULL
         THEN TRUNC(TO_DATE(PREV_SOLD_DATE, 'YYYY-MM-DD'), 'MM')
         ELSE NULL END                        AS PREV_SOLD_MONTH
FROM FDBO.V_REALTOR_FORSALE
WHERE PRICE > 0;


-- ============================================================
-- 3) ANALYTICAL (MULTIDIMENSIONAL) VIEWS
-- ============================================================

-- 3.1 NYC sales by borough/neighborhood/quarter (cube)
CREATE OR REPLACE VIEW FDBO.A_SALES_GEO_TIME_CUBE AS
SELECT
    f.CITY_NAME,
    f.NEIGHBORHOOD_NAME,
    EXTRACT(YEAR FROM f.DATE_KEY)              AS SALE_YEAR,
    TO_NUMBER(TO_CHAR(f.DATE_KEY, 'Q'))        AS SALE_QUARTER,
    COUNT(*)                                   AS NR_SALES,
    ROUND(AVG(f.PRICE_USD), 0)                 AS AVG_PRICE_USD,
    ROUND(MEDIAN(f.PRICE_USD), 0)              AS MEDIAN_PRICE_USD,
    ROUND(SUM(f.PRICE_USD)/1e6, 1)             AS TOTAL_M_USD,
    ROUND(AVG(f.PRICE_PER_SQFT), 2)            AS AVG_PRICE_PER_SQFT
FROM FDBO.F_SALES f
GROUP BY GROUPING SETS (
    (f.CITY_NAME),
    (f.CITY_NAME, EXTRACT(YEAR FROM f.DATE_KEY)),
    (f.CITY_NAME, EXTRACT(YEAR FROM f.DATE_KEY), TO_NUMBER(TO_CHAR(f.DATE_KEY, 'Q'))),
    (f.CITY_NAME, f.NEIGHBORHOOD_NAME, EXTRACT(YEAR FROM f.DATE_KEY))
);

-- 3.2 Rental yield proxy: Amsterdam rentals vs NYC sales (cross-source)
-- Annualized rental potential / NYC median sale price (illustrative)
CREATE OR REPLACE VIEW FDBO.A_RENTAL_VS_SALE AS
WITH rentals_yr AS (
    SELECT CITY_NAME,
           ROUND(AVG(NIGHTLY_PRICE_USD * 365), 0) AS POTENTIAL_ANNUAL_USD
    FROM FDBO.F_RENTALS
    GROUP BY CITY_NAME
),
sales_yr AS (
    SELECT CITY_NAME,
           ROUND(MEDIAN(PRICE_USD), 0) AS MEDIAN_SALE_USD
    FROM FDBO.F_SALES
    GROUP BY CITY_NAME
)
SELECT r.CITY_NAME                       AS RENTAL_CITY,
       r.POTENTIAL_ANNUAL_USD,
       s.CITY_NAME                       AS SALE_CITY,
       s.MEDIAN_SALE_USD,
       ROUND(r.POTENTIAL_ANNUAL_USD * 100.0 / NULLIF(s.MEDIAN_SALE_USD, 0), 2)
                                         AS YIELD_PCT
FROM rentals_yr r
CROSS JOIN sales_yr s
ORDER BY YIELD_PCT DESC;

-- 3.3 NYC sales volume vs mortgage rate (DS1 + DS5 cross-source)
CREATE OR REPLACE VIEW FDBO.A_SALES_VS_MORTGAGE AS
SELECT
    t.YEAR_MONTH,
    m.MORTGAGE_30Y_RATE,
    m.CASE_SHILLER_HPI,
    m.FED_FUNDS_RATE,
    s.NR_SALES,
    s.MEDIAN_PRICE_USD,
    s.TOTAL_M_USD
FROM FDBO.D_TIME t
JOIN FDBO.V_MACRO_INDICATORS m
  ON m.PERIOD_DATE = t.DATE_KEY
LEFT JOIN (
    SELECT TRUNC(SALE_DATE, 'MM') MONTH_KEY,
           COUNT(*) NR_SALES,
           ROUND(MEDIAN(SALE_PRICE), 0) MEDIAN_PRICE_USD,
           ROUND(SUM(SALE_PRICE)/1e6, 1) TOTAL_M_USD
    FROM FDBO.V_NYC_SALES
    GROUP BY TRUNC(SALE_DATE, 'MM')
) s ON s.MONTH_KEY = t.DATE_KEY
ORDER BY t.YEAR_MONTH;

-- 3.4 Realtor.com price-per-sqft by state, weighted avg (DS3 + DS5)
CREATE OR REPLACE VIEW FDBO.A_FORSALE_PPSF_BY_STATE AS
SELECT
    f.REGION_NAME                              AS STATE,
    COUNT(*)                                   AS NR_LISTINGS,
    ROUND(AVG(f.PRICE_USD), 0)                 AS AVG_PRICE_USD,
    ROUND(AVG(f.AREA_SQFT), 0)                 AS AVG_SIZE_SQFT,
    ROUND(SUM(f.PRICE_USD) / NULLIF(SUM(f.AREA_SQFT), 0), 2) AS WEIGHTED_PPSF,
    ROUND(MEDIAN(f.PRICE_PER_SQFT), 2)         AS MEDIAN_PPSF
FROM FDBO.F_FORSALE f
WHERE f.AREA_SQFT > 0
GROUP BY f.REGION_NAME
HAVING COUNT(*) >= 100
ORDER BY WEIGHTED_PPSF DESC;

-- 3.5 Top agents (hosts + brokers) by inventory
CREATE OR REPLACE VIEW FDBO.A_TOP_AGENTS AS
SELECT * FROM (
    SELECT a.AGENT_TYPE, a.AGENT_KEY, a.AGENT_NAME, a.NR_LISTINGS, a.IS_PREMIUM,
           RANK() OVER (PARTITION BY a.AGENT_TYPE ORDER BY a.NR_LISTINGS DESC NULLS LAST) AS RANK_IN_TYPE
    FROM FDBO.D_AGENT a
)
WHERE RANK_IN_TYPE <= 25
ORDER BY AGENT_TYPE, RANK_IN_TYPE;

-- 3.6 Geographic coverage report - which cities have data in 2+ sources
CREATE OR REPLACE VIEW FDBO.A_GEO_COVERAGE AS
WITH src_cities AS (
    SELECT DISTINCT 'DS1_NYC' SRC, CITY_NAME FROM FDBO.F_SALES
    UNION ALL
    SELECT DISTINCT 'DS2_AMS' SRC, CITY_NAME FROM FDBO.F_RENTALS
    UNION ALL
    SELECT DISTINCT 'DS3_REALTOR' SRC, CITY_NAME FROM FDBO.F_FORSALE
)
SELECT CITY_NAME,
       COUNT(DISTINCT SRC) NR_SOURCES,
       LISTAGG(SRC, ',') WITHIN GROUP (ORDER BY SRC) AS SOURCES_LIST
FROM src_cities
GROUP BY CITY_NAME
ORDER BY NR_SOURCES DESC, CITY_NAME;


-- ============================================================
-- 4) VERIFICATION
-- ============================================================
SELECT 'D_TIME'    DIM, COUNT(*) NR FROM FDBO.D_TIME    UNION ALL
SELECT 'D_GEO'     DIM, COUNT(*) NR FROM FDBO.D_GEO     UNION ALL
SELECT 'D_AGENT'   DIM, COUNT(*) NR FROM FDBO.D_AGENT   UNION ALL
SELECT 'F_SALES'   DIM, COUNT(*) NR FROM FDBO.F_SALES   UNION ALL
SELECT 'F_RENTALS' DIM, COUNT(*) NR FROM FDBO.F_RENTALS UNION ALL
SELECT 'F_FORSALE' DIM, COUNT(*) NR FROM FDBO.F_FORSALE;

SELECT * FROM FDBO.A_SALES_VS_MORTGAGE      FETCH FIRST 12 ROWS ONLY;
SELECT * FROM FDBO.A_FORSALE_PPSF_BY_STATE  FETCH FIRST 10 ROWS ONLY;
SELECT * FROM FDBO.A_GEO_COVERAGE           FETCH FIRST 10 ROWS ONLY;
