# Datasets manifest - SII-SIA19

Five visibly-separated data sources powering the Integrated Real Estate Market Analysis System.

---

## DS1 - Oracle XE 21c - NYC Property Sales

* **Theme role**: HISTORICAL SOLD TRANSACTIONS (transaction-level fact table).
* **Source**: NYC Department of Finance, Annualized Rolling Sales.
* **Download**: https://www.nyc.gov/site/finance/property/property-rolling-sales-data.page
* **Files**: `rollingsales_manhattan.csv`, `rollingsales_brooklyn.csv`, `rollingsales_queens.csv`, `rollingsales_bronx.csv`, `rollingsales_statenisland.csv` (one per borough, official `.xlsx` available too).
* **Volume**: ~85,000 rows / 12 months across all five boroughs.
* **License**: NYC Open Data, public domain (NYC OpenData Terms of Use).
* **Why Oracle**: relational + transactional, fits the FDBO pattern from the labs; dataset has clear primary key (block/lot/sale_date), strict types, and a familiar geography for the OLAP joins.
* **Load script**: `11_DS_ORCL_Schema_Sales.sql`.

---

## DS2 - PostgreSQL 14 - Airbnb Rentals + Hosts (Amsterdam)

* **Theme role**: ACTIVE RENTAL LISTINGS + AGENT (host) directory.
* **Source**: Inside Airbnb, quarterly snapshot.
* **Download**: https://insideairbnb.com/get-the-data/  (pick Amsterdam, file `listings.csv.gz` "detailed").
* **Volume**: ~9,000 active listings + ~6,000 unique hosts per quarterly snapshot.
* **License**: Inside Airbnb data is published under CC0 (public domain).
* **Why Postgres**: normalized two-table schema (host -> listing), demo of FOREIGN KEY enforcement and PostgREST role exposure, good fit for the `DSA_SQL_JPA_Postgres` microservice in Part 2.
* **Load script**: `12_DS_PG_Schema_Rentals.sql`.

---

## DS3 - MongoDB 6.0 - For-Sale Listings (Realtor.com)

* **Theme role**: ACTIVE FOR-SALE INVENTORY (current market snapshot).
* **Source**: USA Real Estate Dataset by Ahmed Shahriar Sakib (scraped from Realtor.com).
* **Download**: https://www.kaggle.com/datasets/ahmedshahriarsakib/usa-real-estate-dataset
* **File**: `realtor-data.zip.csv` (compressed CSV inside zip).
* **Volume**: 2.2M+ listings; recommended lab import = 200k random sample (seed 19).
* **License**: CC0 1.0 Universal (Kaggle dataset metadata).
* **Why MongoDB**: schema-less listing documents, optional fields per listing (e.g., `acre_lot`, `prev_sold_date`), perfect for `DSA_NoSQL_MongoDB` microservice in Part 2 and for showing JSON_TABLE federation in Part 1.
* **Load script**: `16_DS_MongoDB_Listings.js`.

---

## DS4 - Neo4j 5.x - Geographic Hierarchy

* **Theme role**: CONFORMED GEO DIMENSION (shared by DS1, DS2, DS3 in the analytical model).
* **Source**: hand-curated graph covering every geography touched by the other four datasets.
* **Volume**: 2 countries, 11 regions, 19 cities, 13 sample neighborhoods.
* **License**: project-internal.
* **Why Neo4j**: the geo dimension is naturally a hierarchy with variable depth (NYC has neighborhoods within boroughs within state; Amsterdam has neighborhoods within province) - a graph traversal handles this far more cleanly than SQL recursion. In the lab pattern this becomes the `Locations` graph queried via Cypher and surfaced as a Hive view in Part 2.
* **Load script**: `18_DS_Neo4J_GeoHierarchy.cypher`.

---

## DS5 - CSV (FRED) - US Real Estate Macro Indicators

* **Theme role**: TIME / MACRO DIMENSION (interest-rate and price-index context).
* **Source**: Federal Reserve Economic Data (St. Louis Fed).
* **Series**:
  * MORTGAGE30US - 30Y Fixed Rate Mortgage Average
  * CSUSHPINSA - Case-Shiller National Home Price Index (NSA)
  * CPIAUCSL - CPI All Urban Consumers
  * FEDFUNDS - Effective Federal Funds Rate
  * HOUST - Housing Starts (thousands, SAAR)
* **Download (per-series CSV)**: https://fred.stlouisfed.org/series/MORTGAGE30US , https://fred.stlouisfed.org/series/CSUSHPINSA , https://fred.stlouisfed.org/series/CPIAUCSL , https://fred.stlouisfed.org/series/FEDFUNDS , https://fred.stlouisfed.org/series/HOUST
* **Volume**: 1 row per month, ~40 rows committed (Jan 2022 - Mar 2025); FRED archives go back to 1971.
* **License**: FRED data is in the public domain (FRED Terms of Use).
* **Why CSV**: explicit "tabular file" source in the federation pattern; demonstrates CSV staging via Oracle external table and Spark `csv` reader.
* **Bundled sample**: `13_DS_CSV_MacroIndicators.csv` (representative; refresh with `fred_refresh.py` for thesis evaluation).
* **Load script**: `13_DS_CSV_MacroIndicators_load.sql`.

---

## Cross-source join keys

| Dimension | Oracle (DS1) | Postgres (DS2) | Mongo (DS3) | Neo4j (DS4) | CSV (DS5) |
|-----------|--------------|----------------|-------------|-------------|-----------|
| **Geo** | `BOROUGH_NAME`, `NEIGHBORHOOD` | `city`, `neighbourhood_cleansed` | `state`, `city` | `City.name`, `Neighborhood.name` | - (national) |
| **Time** | `SALE_DATE` | `last_scraped`, `first_review` | `prev_sold_date` | - | `period_date` |
| **Agent** | - | `host_id` | `brokered_by` | - | - |

These are the keys the Part 2 SparkSQL views use to build the conformed star schema.
