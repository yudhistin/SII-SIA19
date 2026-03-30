 -- AM: Federated View - Oracle SALES + PostgreSQL CUSTOMERS
-- FDBO schema - Cross-source join

CREATE OR REPLACE VIEW FDBO.AM_SALES_CUSTOMERS_FEDERATED AS
SELECT 
    s.SALE_ID, s.SALE_DATE, s.PRODUCT_NAME, s.CATEGORY,
    s.EMPLOYEE_NAME, s.DEPARTMENT_NAME,
    s.QUANTITY, s.TOTAL_AMOUNT,
    c.FIRST_NAME || ' ' || c.LAST_NAME AS CUSTOMER_NAME,
    c.EMAIL AS CUSTOMER_EMAIL,
    c.PHONE AS CUSTOMER_PHONE,
    c.CITY_ID, c.CATEGORY_ID AS CUSTOMER_CATEGORY_ID
FROM FDBO.AM_SALES_VIEW s
JOIN FDBO.AM_POSTGREST_CUSTOMERS_VIEW c ON s.CUSTOMER_ID = c.CUSTOMER_ID;
```

---

Când ai lipit toate fișierele, rulează în Command Prompt:
```
git add -A
git commit -m "Lab 1+2: Data sources Oracle+PG, Access Model views federate"
git push
