-- ============================================================
-- AM: Federated Integration View - all 5 real estate sources
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- V_FEDERATED_PROPERTIES brings DS1+DS2+DS3 onto a single
-- conformed schema (one row per property/listing/transaction)
-- so the analytical layer can treat them uniformly.
--
-- Conformed columns:
--   SOURCE_DB     - which underlying source the row came from
--   PROPERTY_TYPE - 'SOLD' (DS1), 'RENTAL' (DS2), 'FOR_SALE' (DS3)
--   COUNTRY, REGION, CITY, NEIGHBORHOOD - geo (joined to DS4)
--   AGENT_ID      - host (DS2) or broker (DS3); NULL for DS1
--   PRICE_USD     - amount in USD (DS2 EUR converted with EUR_USD_RATE)
--   AREA_SQFT     - living area where reported
--   EVENT_DATE    - transaction or snapshot date
-- ============================================================

-- One-spot constant for the EUR->USD conversion (Amsterdam rentals are EUR).
-- Update or replace with a lookup join against FRED EXR.EURUSD when needed.
CREATE OR REPLACE FUNCTION FDBO.EUR_USD_RATE RETURN NUMBER
DETERMINISTIC AS
BEGIN
    RETURN 1.08;
END;
/

CREATE OR REPLACE VIEW FDBO.V_FEDERATED_PROPERTIES AS
-- DS1: NYC SOLD transactions
SELECT
    'DS1_Oracle_NYC'          AS SOURCE_DB,
    'SOLD'                    AS PROPERTY_TYPE,
    'US'                      AS COUNTRY,
    'NY'                      AS REGION,
    BOROUGH_NAME              AS CITY,
    NEIGHBORHOOD              AS NEIGHBORHOOD,
    NULL                      AS AGENT_ID,
    SALE_PRICE                AS PRICE_USD,
    GROSS_SQUARE_FEET         AS AREA_SQFT,
    SALE_DATE                 AS EVENT_DATE
FROM FDBO.V_NYC_SALES
UNION ALL
-- DS2: Amsterdam RENTAL listings (EUR -> USD)
SELECT
    'DS2_Postgres_AMS'        AS SOURCE_DB,
    'RENTAL'                  AS PROPERTY_TYPE,
    'NL'                      AS COUNTRY,
    'NH'                      AS REGION,
    CITY                      AS CITY,
    NEIGHBOURHOOD             AS NEIGHBORHOOD,
    TO_CHAR(HOST_ID)          AS AGENT_ID,
    PRICE * FDBO.EUR_USD_RATE AS PRICE_USD,
    NULL                      AS AREA_SQFT,
    TO_DATE(LAST_SCRAPED, 'YYYY-MM-DD') AS EVENT_DATE
FROM FDBO.V_AIRBNB_LISTINGS
UNION ALL
-- DS3: Realtor.com FOR_SALE listings
SELECT
    'DS3_Mongo_Realtor'       AS SOURCE_DB,
    'FOR_SALE'                AS PROPERTY_TYPE,
    'US'                      AS COUNTRY,
    STATE                     AS REGION,
    CITY                      AS CITY,
    NULL                      AS NEIGHBORHOOD,
    TO_CHAR(BROKERED_BY)      AS AGENT_ID,
    PRICE                     AS PRICE_USD,
    HOUSE_SIZE                AS AREA_SQFT,
    CASE WHEN PREV_SOLD_DATE IS NOT NULL
         THEN TO_DATE(PREV_SOLD_DATE, 'YYYY-MM-DD')
         ELSE NULL END        AS EVENT_DATE
FROM FDBO.V_REALTOR_FORSALE;

COMMENT ON TABLE FDBO.V_FEDERATED_PROPERTIES IS
    'Federated access view - DS1+DS2+DS3 conformed to a single row-per-property schema';

-- ----------------------- VERIFICATION -----------------------

-- Distribution by source
SELECT SOURCE_DB, PROPERTY_TYPE, COUNT(*) NR_ROWS,
       ROUND(AVG(PRICE_USD), 0) AVG_USD,
       ROUND(SUM(PRICE_USD)/1e6, 1) TOTAL_M_USD
FROM FDBO.V_FEDERATED_PROPERTIES
GROUP BY SOURCE_DB, PROPERTY_TYPE
ORDER BY NR_ROWS DESC;

-- Cross-source join with DS4 geo dimension
SELECT g.COUNTRY_CODE, g.REGION_CODE, g.CITY_NAME,
       COUNT(*) NR_PROPS,
       ROUND(AVG(p.PRICE_USD), 0) AVG_PRICE_USD
FROM FDBO.V_FEDERATED_PROPERTIES p
LEFT JOIN FDBO.V_GEO_HIERARCHY g
       ON UPPER(p.CITY) = UPPER(g.CITY_NAME)
GROUP BY g.COUNTRY_CODE, g.REGION_CODE, g.CITY_NAME
ORDER BY NR_PROPS DESC NULLS LAST
FETCH FIRST 15 ROWS ONLY;

-- Cross-source join with DS5 macro indicators
SELECT TO_CHAR(p.EVENT_DATE, 'YYYY-MM') AS EVENT_MONTH,
       COUNT(*) NR_TRANSACTIONS,
       ROUND(AVG(p.PRICE_USD), 0) AVG_PRICE_USD,
       ROUND(AVG(m.MORTGAGE_30Y_RATE), 2) AVG_MORTGAGE_RATE
FROM   FDBO.V_FEDERATED_PROPERTIES p
LEFT JOIN FDBO.V_MACRO_INDICATORS m
       ON TRUNC(p.EVENT_DATE, 'MM') = m.PERIOD_DATE
WHERE p.PROPERTY_TYPE = 'SOLD'
  AND p.EVENT_DATE >= DATE '2022-01-01'
GROUP BY TO_CHAR(p.EVENT_DATE, 'YYYY-MM')
ORDER BY EVENT_MONTH;
