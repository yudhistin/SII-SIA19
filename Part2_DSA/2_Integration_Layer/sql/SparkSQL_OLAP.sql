-- =============================================================
-- SparkSQL_OLAP.sql
-- Integration / Analytical model in Spark SQL dialect
--
-- Mirrors 3_Integration_Model/31_OLAP_Multidimensional_Analytical.sql
-- but built on the Spark temp views from:
--   DS_DOC_XLSx.sql, DS_SQL_PG.sql, DS_MongoDb.sql
--
-- The geographic dimension lives in Neo4j and is consumed via the WEB layer;
-- for the Spark-only analytical layer we use the geographies that come with
-- each fact source (NYC boroughs in F_SALES, Amsterdam neighbourhoods in
-- F_RENTALS, US states/cities in F_FORSALE).
-- =============================================================


-- ============================================================
-- CONFORMED DIMENSIONS
-- ============================================================

-- D_TIME (month grain)
CREATE OR REPLACE TEMP VIEW d_time AS
SELECT
    period_date                                AS date_key,
    year_no,
    quarter_no,
    month_no,
    DATE_FORMAT(period_date, 'yyyy-MM')        AS year_month,
    CONCAT(year_no, '-Q', quarter_no)          AS year_quarter
FROM v_macro_indicators;

-- D_AGENT (hosts + brokers)
CREATE OR REPLACE TEMP VIEW d_agent AS
SELECT
    CONCAT('HOST_', CAST(host_id AS STRING))   AS agent_key,
    'HOST'                                     AS agent_type,
    host_name                                  AS agent_name,
    host_location                              AS agent_location,
    host_listings_count                        AS nr_listings,
    CASE WHEN host_is_superhost = TRUE THEN 'Y' ELSE 'N' END AS is_premium
FROM v_airbnb_hosts
UNION ALL
SELECT DISTINCT
    CONCAT('BROKER_', CAST(brokered_by AS STRING)) AS agent_key,
    'BROKER'                                       AS agent_type,
    CONCAT('Broker #', CAST(brokered_by AS STRING)) AS agent_name,
    NULL                                           AS agent_location,
    COUNT(*) OVER (PARTITION BY brokered_by)       AS nr_listings,
    'N'                                            AS is_premium
FROM v_realtor_forsale
WHERE brokered_by IS NOT NULL;


-- ============================================================
-- FACT VIEWS
-- ============================================================

-- F_RENTALS (Amsterdam Airbnb snapshot)
CREATE OR REPLACE TEMP VIEW f_rentals AS
SELECT
    listing_id,
    CONCAT('HOST_', CAST(host_id AS STRING))  AS agent_key,
    city                                      AS city_name,
    neighbourhood                             AS neighborhood_name,
    DATE_TRUNC('MONTH', CAST(last_scraped AS DATE)) AS date_key,
    price                                     AS nightly_price_eur,
    price * 1.08                              AS nightly_price_usd,
    price * 1.08 * 30                         AS monthly_price_usd_eq,
    accommodates, bedrooms, beds,
    review_scores_rating,
    availability_365,
    property_type, room_type
FROM v_airbnb_listings;

-- F_FORSALE (Realtor.com inventory)
CREATE OR REPLACE TEMP VIEW f_forsale AS
SELECT
    ROW_NUMBER() OVER (ORDER BY brokered_by, city)   AS forsale_id,
    CONCAT('BROKER_', CAST(brokered_by AS STRING))   AS agent_key,
    city                                              AS city_name,
    state                                             AS region_name,
    price                                             AS price_usd,
    house_size                                        AS area_sqft,
    CASE WHEN house_size > 0 THEN price / house_size ELSE NULL END AS price_per_sqft,
    bed                                               AS bedrooms,
    bath                                              AS bathrooms,
    acre_lot                                          AS lot_acres,
    CASE WHEN prev_sold_date IS NOT NULL
         THEN DATE_TRUNC('MONTH', CAST(prev_sold_date AS DATE))
         ELSE NULL END                                AS prev_sold_month
FROM v_realtor_forsale
WHERE price > 0;


-- ============================================================
-- ANALYTICAL VIEWS
-- ============================================================

-- A_FORSALE_PPSF_BY_STATE
CREATE OR REPLACE TEMP VIEW a_forsale_ppsf_by_state AS
SELECT
    region_name                              AS state,
    COUNT(*)                                 AS nr_listings,
    ROUND(AVG(price_usd), 0)                 AS avg_price_usd,
    ROUND(AVG(area_sqft), 0)                 AS avg_size_sqft,
    ROUND(SUM(price_usd) / NULLIF(SUM(area_sqft), 0), 2) AS weighted_ppsf,
    ROUND(PERCENTILE_APPROX(price_per_sqft, 0.5), 2)     AS median_ppsf
FROM f_forsale
WHERE area_sqft > 0
GROUP BY region_name
HAVING COUNT(*) >= 5
ORDER BY weighted_ppsf DESC;

-- A_TOP_AGENTS
CREATE OR REPLACE TEMP VIEW a_top_agents AS
SELECT * FROM (
    SELECT agent_type, agent_key, agent_name, nr_listings, is_premium,
           RANK() OVER (PARTITION BY agent_type ORDER BY nr_listings DESC NULLS LAST) AS rank_in_type
    FROM   d_agent
) t
WHERE rank_in_type <= 25
ORDER BY agent_type, rank_in_type;

-- A_RENTAL_VS_SALE (placeholder - F_SALES comes from Oracle in Part 1; in
-- Part 2 the NYC sales need either a JDBC link to Oracle or a CSV export).
-- For now, this view aggregates rentals only.
CREATE OR REPLACE TEMP VIEW a_rental_vs_sale AS
SELECT
    city_name                                AS rental_city,
    ROUND(AVG(nightly_price_usd) * 365, 0)   AS potential_annual_usd
FROM f_rentals
GROUP BY city_name
ORDER BY potential_annual_usd DESC;

-- A_SALES_VS_MORTGAGE - placeholder. In Spark we only have the macro side; the
-- NYC sales fact lives in Oracle (Part 1). Emit macro-only rows so the dashboard
-- panel renders without 500.
CREATE OR REPLACE TEMP VIEW a_sales_vs_mortgage AS
SELECT
    year_month,
    mortgage_30y_rate,
    case_shiller_hpi,
    fed_funds_rate,
    CAST(NULL AS INT)    AS nr_sales,
    CAST(NULL AS DOUBLE) AS median_price_usd,
    CAST(NULL AS DOUBLE) AS total_m_usd
FROM d_time t
JOIN v_macro_indicators m ON m.period_date = t.date_key
ORDER BY year_month;

-- A_SALES_GEO_TIME_CUBE - same situation. Emit an empty schema-shaped view.
CREATE OR REPLACE TEMP VIEW a_sales_geo_time_cube AS
SELECT
    CAST(NULL AS STRING) AS city_name,
    CAST(NULL AS STRING) AS neighborhood_name,
    CAST(NULL AS INT)    AS sale_year,
    CAST(NULL AS INT)    AS sale_quarter,
    CAST(NULL AS INT)    AS nr_sales,
    CAST(NULL AS DOUBLE) AS avg_price_usd,
    CAST(NULL AS DOUBLE) AS median_price_usd,
    CAST(NULL AS DOUBLE) AS total_m_usd,
    CAST(NULL AS DOUBLE) AS avg_price_per_sqft
WHERE 1 = 0;

-- A_GEO_COVERAGE
CREATE OR REPLACE TEMP VIEW a_geo_coverage AS
WITH src_cities AS (
    SELECT DISTINCT 'DS2_AMS'     AS src, city_name FROM f_rentals
    UNION ALL
    SELECT DISTINCT 'DS3_REALTOR', city_name FROM f_forsale
)
SELECT city_name,
       COUNT(DISTINCT src) AS nr_sources,
       COLLECT_SET(src)    AS sources_list
FROM src_cities
GROUP BY city_name
ORDER BY nr_sources DESC, city_name;


-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'd_time'    AS view_name, COUNT(*) AS rows FROM d_time   UNION ALL
SELECT 'd_agent',    COUNT(*) FROM d_agent   UNION ALL
SELECT 'f_rentals',  COUNT(*) FROM f_rentals UNION ALL
SELECT 'f_forsale',  COUNT(*) FROM f_forsale;

SELECT * FROM a_forsale_ppsf_by_state LIMIT 10;
SELECT * FROM a_top_agents             LIMIT 10;
SELECT * FROM a_geo_coverage           LIMIT 10;
