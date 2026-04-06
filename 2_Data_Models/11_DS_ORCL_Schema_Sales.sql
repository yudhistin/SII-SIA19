-- ============================================================
-- DS1: Oracle XE 21c -- External Table pentru Retail Sales
-- SII-SIA19: Retail Sales Federated Analysis System
-- Dataset: retail_sales_dataset.csv (Kaggle, 1000 rows)
-- ============================================================
 
-- Pas 1: Creaza directorul Oracle (daca nu exista)
-- Ruleaza ca SYS:
-- CREATE OR REPLACE DIRECTORY EXT_FILE_DS AS '/opt/oracle/oradata/';
-- GRANT READ, WRITE ON DIRECTORY EXT_FILE_DS TO FDBO;
 
-- Pas 2: External Table pentru DS1
CREATE TABLE FDBO.EXT_RETAIL_SALES (
    TRANSACTION_ID   NUMBER,
    SALE_DATE        VARCHAR2(20),
    CUSTOMER_ID      VARCHAR2(20),
    GENDER           VARCHAR2(10),
    AGE              NUMBER,
    PRODUCT_CATEGORY VARCHAR2(50),
    QUANTITY         NUMBER,
    PRICE_PER_UNIT   NUMBER,
    TOTAL_AMOUNT     NUMBER
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
    LOCATION ('retail_sales_dataset.csv')
)
REJECT LIMIT UNLIMITED;
 
-- Pas 3: External Table pentru DS3
CREATE TABLE FDBO.EXT_SALES_SAMPLE (
    ORDER_NUMBER    NUMBER,
    QTY_ORDERED     NUMBER,
    PRICE_EACH      NUMBER,
    ORDER_LINE      NUMBER,
    SALES           NUMBER,
    ORDER_DATE      VARCHAR2(30),
    STATUS          VARCHAR2(20),
    QTR_ID          NUMBER,
    MONTH_ID        NUMBER,
    YEAR_ID         NUMBER,
    PRODUCT_LINE    VARCHAR2(50),
    MSRP            NUMBER,
    PRODUCT_CODE    VARCHAR2(20),
    CUSTOMER_NAME   VARCHAR2(100),
    PHONE           VARCHAR2(30),
    CITY            VARCHAR2(50),
    STATE           VARCHAR2(30),
    COUNTRY         VARCHAR2(50),
    DEAL_SIZE       VARCHAR2(20)
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
    LOCATION ('sales_data_sample.csv')
)
REJECT LIMIT UNLIMITED;
 
-- Test DS1
SELECT COUNT(*) FROM FDBO.EXT_RETAIL_SALES;
-- Expected: 1000
 
-- Test DS3
SELECT COUNT(*) FROM FDBO.EXT_SALES_SAMPLE;
-- Expected: 2823
 
SELECT PRODUCT_LINE, COUNT(*) NR, SUM(SALES) TOTAL
FROM FDBO.EXT_SALES_SAMPLE
GROUP BY PRODUCT_LINE
ORDER BY TOTAL DESC;-- ============================================================
-- DS1: Oracle XE 21c -- External Table pentru Retail Sales
-- SII-SIA19: Retail Sales Federated Analysis System
-- Dataset: retail_sales_dataset.csv (Kaggle, 1000 rows)
-- ============================================================
 
-- Pas 1: Creaza directorul Oracle (daca nu exista)
-- Ruleaza ca SYS:
-- CREATE OR REPLACE DIRECTORY EXT_FILE_DS AS '/opt/oracle/oradata/';
-- GRANT READ, WRITE ON DIRECTORY EXT_FILE_DS TO FDBO;
 
-- Pas 2: External Table pentru DS1
CREATE TABLE FDBO.EXT_RETAIL_SALES (
    TRANSACTION_ID   NUMBER,
    SALE_DATE        VARCHAR2(20),
    CUSTOMER_ID      VARCHAR2(20),
    GENDER           VARCHAR2(10),
    AGE              NUMBER,
    PRODUCT_CATEGORY VARCHAR2(50),
    QUANTITY         NUMBER,
    PRICE_PER_UNIT   NUMBER,
    TOTAL_AMOUNT     NUMBER
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
    LOCATION ('retail_sales_dataset.csv')
)
REJECT LIMIT UNLIMITED;
 
-- Pas 3: External Table pentru DS3
CREATE TABLE FDBO.EXT_SALES_SAMPLE (
    ORDER_NUMBER    NUMBER,
    QTY_ORDERED     NUMBER,
    PRICE_EACH      NUMBER,
    ORDER_LINE      NUMBER,
    SALES           NUMBER,
    ORDER_DATE      VARCHAR2(30),
    STATUS          VARCHAR2(20),
    QTR_ID          NUMBER,
    MONTH_ID        NUMBER,
    YEAR_ID         NUMBER,
    PRODUCT_LINE    VARCHAR2(50),
    MSRP            NUMBER,
    PRODUCT_CODE    VARCHAR2(20),
    CUSTOMER_NAME   VARCHAR2(100),
    PHONE           VARCHAR2(30),
    CITY            VARCHAR2(50),
    STATE           VARCHAR2(30),
    COUNTRY         VARCHAR2(50),
    DEAL_SIZE       VARCHAR2(20)
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
    LOCATION ('sales_data_sample.csv')
)
REJECT LIMIT UNLIMITED;
 
-- Test DS1
SELECT COUNT(*) FROM FDBO.EXT_RETAIL_SALES;
-- Expected: 1000
 
-- Test DS3
SELECT COUNT(*) FROM FDBO.EXT_SALES_SAMPLE;
-- Expected: 2823
 
SELECT PRODUCT_LINE, COUNT(*) NR, SUM(SALES) TOTAL
FROM FDBO.EXT_SALES_SAMPLE
GROUP BY PRODUCT_LINE
ORDER BY TOTAL DESC;