-- ============================================================
-- 00: One-shot reset of FDBO as a LOCAL user inside XEPDB1
-- SII-SIA19: Integrated Real Estate Market Analysis System
--
-- Run ONCE, as SYS connected to XEPDB1 (not the XE/CDB$ROOT service).
-- After this completes, reconnect as FDBO@XEPDB1 and run, in order:
--   1_Data_Sources/11_DS_ORCL_Schema_Sales.sql
--   1_Data_Sources/13_DS_CSV_MacroIndicators_load.sql
--   2_Access_Model/21_*.sql, 23_*.sql, 26_*.sql, 28_*.sql, 29_*.sql, 27_*.sql
--   3_Integration_Model/31_OLAP_Multidimensional_Analytical.sql
--
-- Then back in this SYS@XEPDB1 connection:
--   ORDS_ADMIN.ENABLE_SCHEMA(...);     -- block at the bottom of this file
--
-- Then as FDBO@XEPDB1:
--   4_WEB_Model/41_WEB_REST_Services.sql
-- ============================================================

-- Confirm we are NOT in CDB$ROOT
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS current_container FROM dual;
-- Expected: XEPDB1

-- ---------- Drop the misplaced FDBO if it exists ----------
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'FDBO';
    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP USER FDBO CASCADE';
        DBMS_OUTPUT.PUT_LINE('Old FDBO dropped.');
    END IF;
END;
/

-- ---------- Create FDBO as a strictly LOCAL user ----------
CREATE USER FDBO IDENTIFIED BY fdbo
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE                 TO FDBO;
GRANT CREATE VIEW                       TO FDBO;
GRANT CREATE PROCEDURE                  TO FDBO;
GRANT CREATE SYNONYM                    TO FDBO;
GRANT CREATE MATERIALIZED VIEW          TO FDBO;
GRANT CREATE SESSION                    TO FDBO;

-- HTTP federation needs UTL_HTTP
GRANT EXECUTE ON SYS.UTL_HTTP           TO FDBO;
GRANT EXECUTE ON SYS.UTL_RAW            TO FDBO;
GRANT EXECUTE ON SYS.UTL_ENCODE         TO FDBO;
GRANT EXECUTE ON SYS.UTL_I18N           TO FDBO;

-- ---------- Oracle directory for external CSV/JSON files ----------
CREATE OR REPLACE DIRECTORY EXT_FILE_DS AS '/opt/oracle/oradata/source';
GRANT READ, WRITE ON DIRECTORY EXT_FILE_DS TO FDBO;

-- ---------- Network ACL: FDBO can call out to localhost / host.docker.internal ----------
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'host.docker.internal',
        ace  => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'FDBO',
            principal_type => xs_acl.ptype_db));
END;
/

BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'localhost',
        ace  => xs$ace_type(
            privilege_list => xs$name_list('connect', 'resolve'),
            principal_name => 'FDBO',
            principal_type => xs_acl.ptype_db));
END;
/

-- ---------- Verify ----------
SELECT username, common, common, account_status
FROM   dba_users
WHERE  username = 'FDBO';
-- Expected: FDBO  NO  OPEN

PROMPT
PROMPT FDBO is reset as a local XEPDB1 user. Reconnect as FDBO@XEPDB1 next.
PROMPT
