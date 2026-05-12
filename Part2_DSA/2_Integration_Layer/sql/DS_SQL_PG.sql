-- =============================================================
-- DS_SQL_PG.sql
-- Spark SQL: typed views over Postgres rentals (DS2)
--
-- Prereq: SparkBootstrap registered `pg_host` and `pg_listing` via JDBC.
-- =============================================================

CREATE OR REPLACE TEMP VIEW v_airbnb_hosts AS
SELECT
    host_id,
    host_name,
    host_since,
    host_location,
    host_response_rate,
    host_acceptance_rate,
    host_is_superhost,
    host_listings_count,
    host_identity_verified
FROM pg_host;

CREATE OR REPLACE TEMP VIEW v_airbnb_listings AS
SELECT
    listing_id,
    host_id,
    name,
    neighbourhood_cleansed         AS neighbourhood,
    city,
    latitude, longitude,
    property_type, room_type,
    accommodates, bedrooms, beds,
    CAST(price AS DOUBLE)          AS price,
    minimum_nights,
    availability_365,
    number_of_reviews,
    CAST(review_scores_rating AS DOUBLE) AS review_scores_rating,
    last_scraped
FROM pg_listing;

-- Verification
SELECT 'hosts' AS dim, COUNT(*) FROM v_airbnb_hosts
UNION ALL
SELECT 'listings',     COUNT(*) FROM v_airbnb_listings;

SELECT neighbourhood, room_type,
       COUNT(*)                       AS nr,
       ROUND(AVG(price), 2)           AS avg_price,
       ROUND(AVG(review_scores_rating), 2) AS avg_rating
FROM   v_airbnb_listings
GROUP BY neighbourhood, room_type
ORDER BY nr DESC
LIMIT 15;
