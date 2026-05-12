-- =============================================================
-- DS_DOC_XLSx.sql
-- Spark SQL: typed view over the FRED macro CSV
--
-- Prereq: SparkBootstrap registered `csv_macro` from the DOC microservice
-- (or directly from 1_Data_Sources/13_DS_CSV_MacroIndicators.csv).
-- =============================================================

CREATE OR REPLACE TEMP VIEW v_macro_indicators AS
SELECT
    CAST(period_date AS DATE)               AS period_date,
    YEAR(period_date)                       AS year_no,
    CEIL(MONTH(period_date) / 3.0)          AS quarter_no,
    MONTH(period_date)                      AS month_no,
    mortgage_30y_rate,
    case_shiller_hpi,
    cpi_all_urban,
    fed_funds_rate,
    housing_starts_thousands,
    -- CPI-deflated Case-Shiller index, base = first row in the dataset
    ROUND(
        case_shiller_hpi / NULLIF(cpi_all_urban, 0) *
        (SELECT cpi_all_urban FROM csv_macro
         WHERE period_date = (SELECT MIN(period_date) FROM csv_macro)),
        2
    )                                       AS case_shiller_real_hpi
FROM csv_macro;

-- Verification
SELECT COUNT(*) AS nr_months, MIN(period_date), MAX(period_date) FROM v_macro_indicators;

SELECT year_no,
       ROUND(AVG(mortgage_30y_rate), 2) AS avg_m30,
       ROUND(AVG(case_shiller_hpi), 1)  AS avg_hpi,
       ROUND(AVG(fed_funds_rate), 2)    AS avg_ff
FROM   v_macro_indicators
GROUP BY year_no
ORDER BY year_no;
