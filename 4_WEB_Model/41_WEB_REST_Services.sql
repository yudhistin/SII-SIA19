-- =============================================================
-- P4. REST Web Services Definitions
-- SII-SIA19: Integrated Real Estate Market Analysis System
-- FDBO schema - Web Model (Oracle ORDS)
--
-- This script publishes the analytical views from 3_Integration_Model
-- as REST endpoints via Oracle REST Data Services (ORDS).
--
-- Prereq:
--   1. ORDS installed and configured against this Oracle XE 21c.
--   2. ORDS schema enabled for FDBO:
--        ords_install
--        ords config
--        EXEC ORDS.ENABLE_SCHEMA(p_schema => 'FDBO',
--                                p_url_mapping_pattern => 'realestate');
-- =============================================================


-- -------------------------------------------------------------
-- MODULE: realestate.v1   (base path: /ords/fdbo/realestate/v1)
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name    => 'realestate.v1',
        p_base_path      => '/realestate/v1/',
        p_items_per_page => 100,
        p_status         => 'PUBLISHED',
        p_comments       => 'SII-SIA19 - Integrated Real Estate analytical API');
    COMMIT;
END;
/

-- CORS: allow the static dashboard. Older ORDS versions don't accept
-- p_origins_allowed in DEFINE_MODULE, so set it via UPDATE_MODULE.
BEGIN
    ORDS.UPDATE_MODULE(
        p_module_name      => 'realestate.v1',
        p_origins_allowed  => '*');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Fallback for ORDS versions where UPDATE_MODULE also lacks the param;
        -- run as SYS@XEPDB1:
        --   UPDATE ORDS_METADATA.ORDS_MODULES
        --   SET    ORIGINS_ALLOWED = '*'
        --   WHERE  NAME = 'realestate.v1';
        --   COMMIT;
        DBMS_OUTPUT.PUT_LINE('UPDATE_MODULE not available - apply CORS via SYS table update.');
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 1:  GET /sales/cube
-- Multidimensional NYC sales cube (city / neighborhood / quarter)
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'sales/cube',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'sales/cube',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.A_SALES_GEO_TIME_CUBE
                             ORDER BY CITY_NAME, SALE_YEAR, SALE_QUARTER NULLS FIRST');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 2:  GET /sales/vs-mortgage
-- Monthly NYC sales aligned with FRED mortgage rate / HPI
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'sales/vs-mortgage',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'sales/vs-mortgage',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.A_SALES_VS_MORTGAGE
                             ORDER BY YEAR_MONTH');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 3:  GET /forsale/ppsf-by-state
-- Realtor.com price-per-sqft by US state (weighted)
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'forsale/ppsf-by-state',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'forsale/ppsf-by-state',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.A_FORSALE_PPSF_BY_STATE');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 4:  GET /rentals/yield
-- Rental-vs-sale yield proxy (Amsterdam rentals / NYC sales)
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'rentals/yield',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'rentals/yield',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.A_RENTAL_VS_SALE');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 5:  GET /agents/top
-- Top hosts and brokers by inventory
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'agents/top',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'agents/top',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.A_TOP_AGENTS');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 6:  GET /geo/coverage
-- Cities covered by 2+ data sources
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'geo/coverage',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'geo/coverage',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.A_GEO_COVERAGE');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- ENDPOINT 7:  GET /federated/properties
-- Raw federated rows (DS1+DS2+DS3 conformed)
-- -------------------------------------------------------------
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'realestate.v1',
        p_pattern     => 'federated/properties',
        p_priority    => 0);
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'realestate.v1',
        p_pattern        => 'federated/properties',
        p_method         => 'GET',
        p_source_type    => ORDS.source_type_collection_feed,
        p_source         => 'SELECT * FROM FDBO.V_FEDERATED_PROPERTIES
                             FETCH FIRST 1000 ROWS ONLY');
    COMMIT;
END;
/


-- -------------------------------------------------------------
-- VERIFY MODULE  (column names valid for ORDS 22.x+)
-- -------------------------------------------------------------
SELECT name, uri_prefix, status FROM user_ords_modules
WHERE  name = 'realestate.v1';

SELECT t.uri_template, h.method
FROM   user_ords_templates t
JOIN   user_ords_handlers  h ON h.template_id = t.id
WHERE  t.module_id IN (SELECT id FROM user_ords_modules WHERE name = 'realestate.v1')
ORDER BY t.uri_template;

-- After running, the endpoints will be available at (assuming ORDS on :8080):
--   http://localhost:8181/ords/fdbo/realestate/v1/sales/cube
--   http://localhost:8181/ords/fdbo/realestate/v1/sales/vs-mortgage
--   http://localhost:8181/ords/fdbo/realestate/v1/forsale/ppsf-by-state
--   http://localhost:8181/ords/fdbo/realestate/v1/rentals/yield
--   http://localhost:8181/ords/fdbo/realestate/v1/agents/top
--   http://localhost:8181/ords/fdbo/realestate/v1/geo/coverage
--   http://localhost:8181/ords/fdbo/realestate/v1/federated/properties
