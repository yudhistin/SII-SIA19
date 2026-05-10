-- ============================================================
-- AM (DS5): Oracle Access View on FRED Macro Indicators (CSV)
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Federation pattern: LOCAL VIEW on a typed table loaded from
--                     an Oracle external table (CSV).
-- Underlying table  : FDBO.RE_MACRO_DIM (loaded by
--                     13_DS_CSV_MacroIndicators_load.sql)
-- ============================================================

CREATE OR REPLACE VIEW FDBO.V_MACRO_INDICATORS AS
SELECT
    PERIOD_DATE,
    YEAR_NO,
    QUARTER_NO,
    MONTH_NO,
    MORTGAGE_30Y_RATE,
    CASE_SHILLER_HPI,
    CPI_ALL_URBAN,
    FED_FUNDS_RATE,
    HOUSING_STARTS_THOUSANDS,
    -- Real (CPI-deflated) Case-Shiller index, base = first row in the dataset
    ROUND(
        CASE_SHILLER_HPI / NULLIF(CPI_ALL_URBAN, 0)
        * (SELECT CPI_ALL_URBAN FROM FDBO.RE_MACRO_DIM
           WHERE PERIOD_DATE = (SELECT MIN(PERIOD_DATE) FROM FDBO.RE_MACRO_DIM)),
        2
    ) AS CASE_SHILLER_REAL_HPI
FROM FDBO.RE_MACRO_DIM;

COMMENT ON TABLE FDBO.V_MACRO_INDICATORS IS
    'DS5 access view - FRED monthly macro indicators (mortgage rate, HPI, CPI, FF, housing starts)';

-- ----------------------- VERIFICATION -----------------------
SELECT COUNT(*) NR_MONTHS, MIN(PERIOD_DATE) FROM_DATE, MAX(PERIOD_DATE) TO_DATE
FROM FDBO.V_MACRO_INDICATORS;

SELECT YEAR_NO,
       ROUND(AVG(MORTGAGE_30Y_RATE), 2) AVG_M30,
       ROUND(AVG(CASE_SHILLER_HPI), 1)  AVG_HPI_NOMINAL,
       ROUND(AVG(CASE_SHILLER_REAL_HPI), 1) AVG_HPI_REAL,
       ROUND(AVG(FED_FUNDS_RATE), 2)    AVG_FF
FROM FDBO.V_MACRO_INDICATORS
GROUP BY YEAR_NO
ORDER BY YEAR_NO;
