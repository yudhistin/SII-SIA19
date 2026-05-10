-- ============================================================
-- DS5: CSV - US Real Estate Macro Indicators (FRED)
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Series (all monthly, US national):
--   MORTGAGE30US  - 30-Year Fixed Rate Mortgage Average (% APR)
--   CSUSHPINSA    - S&P/Case-Shiller U.S. National Home Price Index (NSA)
--   CPIAUCSL      - CPI for All Urban Consumers, All Items (1982-84=100)
--   FEDFUNDS      - Effective Federal Funds Rate (%)
--   HOUST         - Housing Starts: Total (thousands of units, SAAR)
--
-- Source     : https://fred.stlouisfed.org/series/MORTGAGE30US
--              https://fred.stlouisfed.org/series/CSUSHPINSA
--              https://fred.stlouisfed.org/series/CPIAUCSL
--              https://fred.stlouisfed.org/series/FEDFUNDS
--              https://fred.stlouisfed.org/series/HOUST
-- File       : 13_DS_CSV_MacroIndicators.csv
-- Role       : MACRO/TIME dimension feeding the analytical model.
-- Note       : The bundled CSV is a representative monthly sample
--              (Jan 2022 - Mar 2025) for self-contained lab runs.
--              For thesis evaluation, refresh from FRED via:
--                  fred_refresh.py  (see comments below)
-- ============================================================

-- =================================================================
-- LOAD INTO ORACLE (option A) - external table on the same directory
-- =================================================================
CREATE TABLE FDBO.EXT_RE_MACRO (
    PERIOD_DATE                 VARCHAR2(12),
    MORTGAGE_30Y_RATE           NUMBER,
    CASE_SHILLER_HPI            NUMBER,
    CPI_ALL_URBAN               NUMBER,
    FED_FUNDS_RATE              NUMBER,
    HOUSING_STARTS_THOUSANDS    NUMBER
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY EXT_FILE_DS
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        SKIP 1
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
    )
    LOCATION ('13_DS_CSV_MacroIndicators.csv')
)
REJECT LIMIT UNLIMITED;

-- Materialized typed dimension
CREATE TABLE FDBO.RE_MACRO_DIM (
    PERIOD_DATE                 DATE PRIMARY KEY,
    YEAR_NO                     NUMBER,
    QUARTER_NO                  NUMBER,
    MONTH_NO                    NUMBER,
    MORTGAGE_30Y_RATE           NUMBER,
    CASE_SHILLER_HPI            NUMBER,
    CPI_ALL_URBAN               NUMBER,
    FED_FUNDS_RATE              NUMBER,
    HOUSING_STARTS_THOUSANDS    NUMBER
);

INSERT INTO FDBO.RE_MACRO_DIM
SELECT
    TO_DATE(PERIOD_DATE, 'YYYY-MM-DD'),
    EXTRACT(YEAR  FROM TO_DATE(PERIOD_DATE, 'YYYY-MM-DD')),
    TO_NUMBER(TO_CHAR(TO_DATE(PERIOD_DATE, 'YYYY-MM-DD'), 'Q')),
    EXTRACT(MONTH FROM TO_DATE(PERIOD_DATE, 'YYYY-MM-DD')),
    MORTGAGE_30Y_RATE,
    CASE_SHILLER_HPI,
    CPI_ALL_URBAN,
    FED_FUNDS_RATE,
    HOUSING_STARTS_THOUSANDS
FROM FDBO.EXT_RE_MACRO;

COMMIT;

SELECT YEAR_NO, QUARTER_NO,
       ROUND(AVG(MORTGAGE_30Y_RATE), 2) AVG_M30,
       ROUND(AVG(CASE_SHILLER_HPI), 1)  AVG_HPI,
       ROUND(AVG(FED_FUNDS_RATE), 2)    AVG_FF
FROM FDBO.RE_MACRO_DIM
GROUP BY YEAR_NO, QUARTER_NO
ORDER BY YEAR_NO, QUARTER_NO;


-- =================================================================
-- LOAD INTO POSTGRES (option B) - mirror copy used by SparkSQL
-- =================================================================
-- CREATE SCHEMA IF NOT EXISTS macro;
-- CREATE TABLE macro.indicators (
--     period_date              DATE PRIMARY KEY,
--     mortgage_30y_rate        NUMERIC(6,2),
--     case_shiller_hpi         NUMERIC(8,2),
--     cpi_all_urban            NUMERIC(8,2),
--     fed_funds_rate           NUMERIC(6,2),
--     housing_starts_thousands INTEGER
-- );
-- \COPY macro.indicators FROM '/tmp/13_DS_CSV_MacroIndicators.csv' CSV HEADER;


-- =================================================================
-- REFRESH FROM FRED (production option) - requires free API key
-- =================================================================
-- See companion script: fred_refresh.py
-- Usage:
--   pip install pandas fredapi
--   export FRED_API_KEY=<your_key>
--   python fred_refresh.py > 13_DS_CSV_MacroIndicators.csv
