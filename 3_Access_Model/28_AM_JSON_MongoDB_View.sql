-- ============================================================
-- AM: MongoDB Access via JSON Export + DBMS_LOB + JSON_TABLE
-- SII-SIA19: Retail Sales Federated Analysis System
-- Dataset: online_retail_II.xlsx -> online_retail_array.json
-- Collection: mds.OnlineRetail (541910 documents)
-- ============================================================
 
-- Pas 1: Export din MongoDB (1000 documente, format JSON array)
-- docker exec -it mongodb-6.0 mongoexport \
--   --db mds --collection OnlineRetail \
--   --limit 1000 --jsonArray \
--   --out /tmp/online_retail_array.json
 
-- Pas 2: Transfer prin Windows (nu se poate face docker cp direct intre containere)
-- docker cp mongodb-6.0:/tmp/online_retail_array.json "C:\Users\YudHistin\SII-SIA19\1_Data_Sources\online_retail_array.json"
-- docker cp "C:\Users\YudHistin\SII-SIA19\1_Data_Sources\online_retail_array.json" oracle-xe-21c:/opt/oracle/oradata/
 
-- Pas 3: Functia PL/SQL care citeste JSON array cu DBMS_LOB
-- (UTL_FILE nu poate citi fisiere cu linii > 32767 chars, de aceea folosim DBMS_LOB)
CREATE OR REPLACE FUNCTION FDBO.GET_JSON_FILE RETURN CLOB AS
    v_bfile        BFILE;
    v_clob         CLOB;
    v_dest_offset  NUMBER := 1;
    v_src_offset   NUMBER := 1;
    v_lang_ctx     NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
    v_warning      NUMBER;
BEGIN
    v_bfile := BFILENAME('EXT_FILE_DS', 'online_retail_array.json');
    DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);
    DBMS_LOB.FILEOPEN(v_bfile, DBMS_LOB.FILE_READONLY);
    DBMS_LOB.LOADCLOBFROMFILE(
        v_clob, v_bfile,
        DBMS_LOB.GETLENGTH(v_bfile),
        v_dest_offset, v_src_offset,
        871, v_lang_ctx, v_warning
    );
    DBMS_LOB.FILECLOSE(v_bfile);
    RETURN v_clob;
END;
/
 
-- Pas 4: View DS4 -- parseaza JSON array MongoDB
CREATE OR REPLACE VIEW FDBO.V_ONLINE_RETAIL AS
SELECT *
FROM JSON_TABLE(
    FDBO.GET_JSON_FILE(),
    '$[*]' COLUMNS (
        INVOICE         VARCHAR2(20)  PATH '$.Invoice',
        STOCKCODE       VARCHAR2(20)  PATH '$.StockCode',
        DESCRIPTION     VARCHAR2(200) PATH '$.Description',
        QUANTITY        NUMBER        PATH '$.Quantity',
        PRICE           NUMBER        PATH '$.Price',
        COUNTRY         VARCHAR2(50)  PATH '$.Country'
    )
);
 
-- Test
SELECT COUNT(*) FROM FDBO.V_ONLINE_RETAIL;
-- Expected: 1000
 
SELECT COUNTRY, COUNT(*) NR, ROUND(SUM(QUANTITY * PRICE), 2) TOTAL
FROM FDBO.V_ONLINE_RETAIL
GROUP BY COUNTRY
ORDER BY TOTAL DESC
FETCH FIRST 5 ROWS ONLY;