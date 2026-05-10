# SII-SIA19 - Integrated Real Estate Market Analysis System

Federated Database / OLAP project (SII master, year 2). Five visibly-separated heterogeneous data sources are integrated into a single analytical model that drives a REST web layer.

## Architecture at a glance

```
+------------------+   +------------------+   +------------------+
| Oracle XE 21c    |   | PostgreSQL 14    |   | MongoDB 6.0      |
| Sales (NYC DOF)  |   | Rentals + Hosts  |   | For-sale (US)    |
| ~85k rows        |   | (Airbnb AMS)     |   | ~200k JSON docs  |
+--------+---------+   +--------+---------+   +--------+---------+
         |                      |                      |
         |              +-------+-------+              |
         +------------- |  Spark SQL    | -------------+
                        | Integration   |
                        | + Analytics   |
                        +-------+-------+
                                |
                +---------------+----------------+
                |                                |
       +--------+-------+              +---------+--------+
       | Neo4j 5.x      |              | CSV (FRED)       |
       | Geo hierarchy  |              | Macro indicators |
       +----------------+              +------------------+
                                |
                        +-------+-------+
                        | DSA WEB REST  |
                        | (Spring Boot) |
                        +---------------+
```

## Data sources (5, intentionally heterogeneous)

| # | Engine | Segment | Dataset | Where it lives |
|---|--------|---------|---------|----------------|
| 1 | Oracle XE 21c | Historical sales | NYC Dept. of Finance Rolling Sales | `1_Data_Sources/11_DS_ORCL_Schema_Sales.sql` |
| 2 | PostgreSQL 14 | Rentals + agents | Inside Airbnb (Amsterdam) | `1_Data_Sources/12_DS_PG_Schema_Rentals.sql` |
| 3 | MongoDB 6.0 | For-sale listings | Realtor.com USA (Kaggle) | `1_Data_Sources/16_DS_MongoDB_Listings.js` |
| 4 | Neo4j 5.x | Geographic hierarchy | Custom (covers DS1+DS2+DS3) | `1_Data_Sources/18_DS_Neo4J_GeoHierarchy.cypher` |
| 5 | CSV (FRED) | Macro indicators | Mortgage rate, HPI, CPI, FF, Housing Starts | `1_Data_Sources/13_DS_CSV_MacroIndicators.csv` |

See `1_Data_Sources/DATASETS.md` for full download links, license notes, and refresh instructions.

## Repository layout

```
1_Data_Sources/      DDL + load scripts for the 5 source systems
2_Access_Model/      Federated access views (Oracle DB Links, FDW, JSON_TABLE, ...)
3_Integration_Model/ Conformed dimensions + analytical (OLAP) views
4_WEB_Model/         REST layer (Oracle ORDS in P1, Spring Boot in P2)
```

## Part 1 vs Part 2

* **Part 1 (this commit)**: federation done inside Oracle (DB Links, external tables, JSON_TABLE, MongoDB JSON via APEX). Five sources, four `Px_*.docx` design documents, four SQL deliverables.
* **Part 2 (next)**: federation moved to **Spark SQL**, with Java/Spring Boot microservices wrapping each source (DSA architecture). REST endpoints surface the analytical views.

## How to run locally

Each source brings its own container/script. Quick start:

```bash
# Oracle
docker run -d --name oracle-xe-21c -p 1521:1521 gvenzl/oracle-xe:21-slim

# Postgres
docker run -d --name postgresql-container -p 5432:5432 -e POSTGRES_PASSWORD=pg postgres:14

# MongoDB
docker run -d --name mongodb-6.0 -p 27017:27017 mongo:6.0

# Neo4j
docker run -d --name neo4j -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/test1234 neo4j:5
```

Then run the scripts in `1_Data_Sources/` in numerical order.
