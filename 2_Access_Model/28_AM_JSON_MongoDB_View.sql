CREATE OR REPLACE FUNCTION FDBO.GET_NEO4J_DATA(p_query VARCHAR2) 
RETURN CLOB AS
    v_url     VARCHAR2(500) := 'http://host.docker.internal:7474/db/neo4j/query/v2';
    v_req     UTL_HTTP.REQ;
    v_resp    UTL_HTTP.RESP;
    v_buffer  VARCHAR2(32767);
    v_result  CLOB := '';
    v_body    VARCHAR2(1000);
BEGIN
    v_body := '{"statement": "' || p_query || '"}';
    v_req := UTL_HTTP.BEGIN_REQUEST(v_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_HEADER(v_req, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(v_req, 'Authorization', 'Basic bmVvNGo6bmVvNGpfYWRtaW4=');
    UTL_HTTP.SET_HEADER(v_req, 'Content-Length', LENGTH(v_body));
    UTL_HTTP.WRITE_TEXT(v_req, v_body);
    v_resp := UTL_HTTP.GET_RESPONSE(v_req);
    LOOP
        BEGIN
            UTL_HTTP.READ_LINE(v_resp, v_buffer, TRUE);
            v_result := v_result || v_buffer;
        EXCEPTION
            WHEN UTL_HTTP.END_OF_BODY THEN EXIT;
        END;
    END LOOP;
    UTL_HTTP.END_RESPONSE(v_resp);
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN RETURN SQLERRM;
END;
/

CREATE OR REPLACE VIEW FDBO.AM_NEO4J_LOCATIONS AS
SELECT jt.CITY_ID, jt.CITY_NAME, jt.POSTAL_CODE,
       jt.DEPARTMENT_NAME, jt.COUNTRY_NAME
FROM JSON_TABLE(
    GET_NEO4J_DATA('MATCH (c:City) -[r:LOCATED_IN]-> (d:Departament) RETURN c.idCity, c.cityName, c.postalCode, d.departamentName, d.countryName'),
    '$.data.values[*]'
    COLUMNS (
        CITY_ID         NUMBER        PATH '$[0]',
        CITY_NAME       VARCHAR2(100) PATH '$[1]',
        POSTAL_CODE     VARCHAR2(10)  PATH '$[2]',
        DEPARTMENT_NAME VARCHAR2(100) PATH '$[3]',
        COUNTRY_NAME    VARCHAR2(50)  PATH '$[4]'
    )
) jt;