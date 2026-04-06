 -- ============================================================
-- DS2: PostgreSQL 14 -- Schema si import customer_shopping_data
-- SII-SIA19: Retail Sales Federated Analysis System
-- Dataset: customer_shopping_data.csv (Kaggle, 99457 rows)
-- ============================================================
 
-- Pas 1: Copiaza fisierul in container
-- docker cp "C:\Users\YudHistin\SII-SIA19\1_Data_Sources\customer_shopping_data.csv" postgresql-container:/tmp/
 
-- Pas 2: Creaza schema si tabela
CREATE SCHEMA IF NOT EXISTS customers;
 
CREATE TABLE IF NOT EXISTS customers.shopping_data (
    invoice_no      VARCHAR(20),
    customer_id     VARCHAR(20),
    gender          VARCHAR(10),
    age             INTEGER,
    category        VARCHAR(50),
    quantity        INTEGER,
    price           NUMERIC(10,2),
    payment_method  VARCHAR(30),
    invoice_date    VARCHAR(20),
    shopping_mall   VARCHAR(50)
);
 
-- Pas 3: Import CSV
-- docker exec -it postgresql-container psql -U postgres -c
-- "\COPY customers.shopping_data FROM '/tmp/customer_shopping_data.csv' CSV HEADER DELIMITER ',';"
 
-- Pas 4: Creaza rolul web_anon pentru PostgREST
CREATE ROLE web_anon NOLOGIN;
GRANT USAGE ON SCHEMA customers TO web_anon;
GRANT SELECT ON customers.shopping_data TO web_anon;
 
-- Test
SELECT COUNT(*) FROM customers.shopping_data;
-- Expected: 99457
 
SELECT gender, category, COUNT(*) NR, ROUND(AVG(price)::numeric, 2) AVG_PRICE
FROM customers.shopping_data
GROUP BY gender, category
ORDER BY NR DESC
LIMIT 10;
 
