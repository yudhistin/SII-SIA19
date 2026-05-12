-- =============================================================
-- DS_MongoDb.sql
-- Spark SQL: typed view over MongoDB realestate.forsale (DS3)
--
-- Prereq: SparkBootstrap registered `mongo_forsale` via mongo-spark-connector.
-- =============================================================

CREATE OR REPLACE TEMP VIEW v_realtor_forsale AS
SELECT
    brokered_by,
    status,
    CAST(price      AS DOUBLE) AS price,
    CAST(bed        AS INT)    AS bed,
    CAST(bath       AS INT)    AS bath,
    CAST(acre_lot   AS DOUBLE) AS acre_lot,
    street,
    city,
    state,
    CAST(zip_code   AS STRING) AS zip_code,
    CAST(house_size AS DOUBLE) AS house_size,
    prev_sold_date
FROM mongo_forsale
WHERE status = 'for_sale';

-- Verification
SELECT COUNT(*) AS nr_listings FROM v_realtor_forsale;

SELECT state,
       COUNT(*)                  AS nr_listings,
       ROUND(AVG(price), 0)      AS avg_price,
       ROUND(AVG(house_size), 0) AS avg_size
FROM   v_realtor_forsale
WHERE  price > 0 AND house_size > 0
GROUP BY state
ORDER BY nr_listings DESC
LIMIT 15;
