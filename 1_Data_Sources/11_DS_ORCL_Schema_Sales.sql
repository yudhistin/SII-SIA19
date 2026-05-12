-- ============================================================
-- DS1: Oracle XE 21c - External Table for NYC Property Sales
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Dataset: NYC Department of Finance - Rolling Sales
-- Source : https://www.nyc.gov/site/finance/property/property-rolling-sales-data.page
-- Files  : rollingsales_manhattan.csv, rollingsales_brooklyn.csv,
--          rollingsales_queens.csv, rollingsales_bronx.csv,
--          rollingsales_statenisland.csv
-- Volume : ~85,000 rows / 12 months (all 5 boroughs combined)
-- Role   : Historical SOLD transactions (transaction-level granularity)
-- ============================================================

-- Pas 1: Create Oracle directory (run as SYS once)
-- CREATE OR REPLACE DIRECTORY EXT_FILE_DS AS '/opt/oracle/oradata/';
-- GRANT READ, WRITE ON DIRECTORY EXT_FILE_DS TO FDBO;

-- Pas 2: NYC publishes the rolling sales as XLSX. Convert each to CSV first
-- (helper script: prepare_data.py converts all 5 boroughs in one run), then:
-- docker cp rollingsales_manhattan.csv      oracle-xe-21c:/opt/oracle/oradata/
-- docker cp rollingsales_brooklyn.csv       oracle-xe-21c:/opt/oracle/oradata/
-- docker cp rollingsales_queens.csv         oracle-xe-21c:/opt/oracle/oradata/
-- docker cp rollingsales_bronx.csv          oracle-xe-21c:/opt/oracle/oradata/
-- docker cp rollingsales_statenisland.csv   oracle-xe-21c:/opt/oracle/oradata/

-- Pas 3: External Table - one per borough (NYC publishes one CSV per borough)
-- The header layout below matches the 21-column Rolling Sales spec.
CREATE TABLE FDBO.EXT_NYC_SALES_MANHATTAN (
    BOROUGH                       NUMBER,
    NEIGHBORHOOD                  VARCHAR2(60),
    BUILDING_CLASS_CATEGORY       VARCHAR2(60),
    TAX_CLASS_AT_PRESENT          VARCHAR2(4),
    BLOCK                         NUMBER,
    LOT                           NUMBER,
    EASEMENT                      VARCHAR2(20),
    BUILDING_CLASS_AT_PRESENT     VARCHAR2(4),
    ADDRESS                       VARCHAR2(120),
    APARTMENT_NUMBER              VARCHAR2(20),
    ZIP_CODE                      VARCHAR2(10),
    RESIDENTIAL_UNITS             NUMBER,
    COMMERCIAL_UNITS              NUMBER,
    TOTAL_UNITS                   NUMBER,
    LAND_SQUARE_FEET              VARCHAR2(20),
    GROSS_SQUARE_FEET             VARCHAR2(20),
    YEAR_BUILT                    NUMBER,
    TAX_CLASS_AT_TIME_OF_SALE     VARCHAR2(4),
    BUILDING_CLASS_AT_TIME_OF_SALE VARCHAR2(4),
    SALE_PRICE                    VARCHAR2(20),
    SALE_DATE                     VARCHAR2(20)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY EXT_FILE_DS
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        SKIP 5
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
    )
    LOCATION ('rollingsales_manhattan.csv')
)
REJECT LIMIT UNLIMITED;

-- Pas 4: Materialized normalized table - convert text to typed columns
CREATE TABLE FDBO.NYC_PROPERTY_SALES (
    SALE_ID                       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    BOROUGH                       NUMBER,
    BOROUGH_NAME                  VARCHAR2(20),
    NEIGHBORHOOD                  VARCHAR2(60),
    BUILDING_CLASS_CATEGORY       VARCHAR2(60),
    ADDRESS                       VARCHAR2(120),
    ZIP_CODE                      VARCHAR2(10),
    RESIDENTIAL_UNITS             NUMBER,
    COMMERCIAL_UNITS              NUMBER,
    TOTAL_UNITS                   NUMBER,
    LAND_SQUARE_FEET              NUMBER,
    GROSS_SQUARE_FEET             NUMBER,
    YEAR_BUILT                    NUMBER,
    SALE_PRICE                    NUMBER,
    SALE_DATE                     DATE
);

-- Pas 5: Load Manhattan (repeat with UNION ALL for the other 4 boroughs)
INSERT INTO FDBO.NYC_PROPERTY_SALES
    (BOROUGH, BOROUGH_NAME, NEIGHBORHOOD, BUILDING_CLASS_CATEGORY,
     ADDRESS, ZIP_CODE, RESIDENTIAL_UNITS, COMMERCIAL_UNITS, TOTAL_UNITS,
     LAND_SQUARE_FEET, GROSS_SQUARE_FEET, YEAR_BUILT, SALE_PRICE, SALE_DATE)
SELECT
    BOROUGH,
    'MANHATTAN',
    NEIGHBORHOOD,
    BUILDING_CLASS_CATEGORY,
    ADDRESS,
    ZIP_CODE,
    RESIDENTIAL_UNITS,
    COMMERCIAL_UNITS,
    TOTAL_UNITS,
    TO_NUMBER(REPLACE(NULLIF(TRIM(LAND_SQUARE_FEET), '-'), ',', ''))   AS LAND_SQUARE_FEET,
    TO_NUMBER(REPLACE(NULLIF(TRIM(GROSS_SQUARE_FEET), '-'), ',', ''))  AS GROSS_SQUARE_FEET,
    YEAR_BUILT,
    TO_NUMBER(REPLACE(NULLIF(TRIM(SALE_PRICE), '-'), ',', ''))         AS SALE_PRICE,
    -- NYC publishes SALE DATE as a timestamp (YYYY-MM-DD HH24:MI:SS).
    TO_DATE(SUBSTR(TRIM(SALE_DATE), 1, 19), 'YYYY-MM-DD HH24:MI:SS')   AS SALE_DATE
FROM FDBO.EXT_NYC_SALES_MANHATTAN
WHERE TRIM(SALE_PRICE) IS NOT NULL
  AND TRIM(SALE_PRICE) <> '-'
  AND TO_NUMBER(REPLACE(SALE_PRICE, ',', '')) > 0;

COMMIT;

-- Pas 6: Verification
SELECT BOROUGH_NAME, COUNT(*) NR_SALES,
       ROUND(AVG(SALE_PRICE), 0)  AVG_PRICE,
       ROUND(MEDIAN(SALE_PRICE), 0) MEDIAN_PRICE
FROM FDBO.NYC_PROPERTY_SALES
GROUP BY BOROUGH_NAME
ORDER BY NR_SALES DESC;

-- Top neighborhoods by total transaction value (Manhattan example)
SELECT NEIGHBORHOOD, COUNT(*) NR_SALES, SUM(SALE_PRICE) TOTAL_VOLUME
FROM FDBO.NYC_PROPERTY_SALES
WHERE BOROUGH_NAME = 'MANHATTAN'
GROUP BY NEIGHBORHOOD
ORDER BY TOTAL_VOLUME DESC
FETCH FIRST 10 ROWS ONLY;
