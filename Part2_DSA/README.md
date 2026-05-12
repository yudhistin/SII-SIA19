# Part 2 — DSA (Data Service Architecture)

Spring Boot microservices + Spark SQL replacing the Oracle-centric federation from Part 1.

## Layout

```
Part2_DSA/
├── 1_Access_Layer/
│   ├── DSA_DOC_XLSx/         port 8091  — wraps FRED macro CSV
│   ├── DSA_SQL_JPA_Postgres/ port 8092  — wraps Postgres rentals
│   └── DSA_NoSQL_MongoDB/    port 8093  — wraps Mongo realestate.forsale
├── 2_Integration_Layer/
│   ├── DSA-SparkSQL-Service/ port 8094  — embedded Spark SQL + /sql endpoint
│   └── sql/
│       ├── DS_DOC_XLSx.sql   — typed view over FRED macro
│       ├── DS_SQL_PG.sql     — typed views over rentals
│       ├── DS_MongoDb.sql    — typed view over for-sale listings
│       └── SparkSQL_OLAP.sql — analytical views (rebuilt from Part 1's OLAP)
└── 3_WEB_Layer/
    └── DSA_WEB_RESTService/  port 8095  — final REST API (Hive JDBC or HTTP)
```

## Architecture

```
                     ┌───────────────────────────────────────┐
                     │   DSA_WEB_RESTService  (port 8095)    │
                     │   Hive JDBC  /  HTTP fallback         │
                     └────────────────────┬──────────────────┘
                                          │  SQL
                          ┌───────────────▼───────────────┐
                          │ DSA-SparkSQL-Service (8094)   │
                          │   Spark SQL temp views        │
                          │   + analytical OLAP views     │
                          └───┬────────────┬───────────┬──┘
            JDBC pg_*         │            │           │   mongo-spark
        ┌────────────────────┘     CSV file path       └─────────────────┐
        ▼                              ▼                                  ▼
 Postgres rentals.*           1_Data_Sources/                       Mongo realestate.forsale
 (port 5432)                  13_DS_CSV_Macro                       (port 27017)
        ▲                              ▲                                  ▲
        │                              │                                  │
 DSA_SQL_JPA_Postgres        DSA_DOC_XLSx                        DSA_NoSQL_MongoDB
 (8092, /api/listings)        (8091, /api/macro)                  (8093, /api/forsale)
```

## Build everything

Each project is a standalone Maven module. From its directory:

```cmd
mvn clean package
```

Or use the IDE (IntelliJ / VS Code with Java extension) to import each `pom.xml`.

## Run order

Start in this order so each layer can reach its dependencies:

1. **Containers** — Postgres, MongoDB (already up from Part 1).
2. **Access Layer microservices** (each in its own terminal):
   ```cmd
   cd Part2_DSA\1_Access_Layer\DSA_DOC_XLSx        & mvn spring-boot:run
   cd Part2_DSA\1_Access_Layer\DSA_SQL_JPA_Postgres & mvn spring-boot:run
   cd Part2_DSA\1_Access_Layer\DSA_NoSQL_MongoDB    & mvn spring-boot:run
   ```
3. **SparkSQL service**:
   ```cmd
   cd Part2_DSA\2_Integration_Layer\DSA-SparkSQL-Service
   mvn spring-boot:run
   ```
   On startup it reads CSV/Postgres/Mongo, registers base views, then runs the 4 SQL scripts to define typed + analytical views.
4. **WEB REST service**:
   ```cmd
   cd Part2_DSA\3_WEB_Layer\DSA_WEB_RESTService
   mvn spring-boot:run
   ```
   Default driver is `http` (talks to SparkSQL on :8094). Switch to Hive JDBC by setting `app.driver=hive` in its `application.yml` and enabling `spark.thrift.enabled=true` in the SparkSQL service.

## Smoke tests

```cmd
:: Access Layer
curl http://localhost:8091/api/macro
curl http://localhost:8092/api/listings?size=5
curl http://localhost:8093/api/forsale?size=5

:: Integration Layer (Spark SQL)
curl "http://localhost:8094/sql/tables"
curl "http://localhost:8094/sql?q=SELECT+*+FROM+a_forsale_ppsf_by_state+LIMIT+5"

:: WEB Layer
curl http://localhost:8095/realestate/v1/forsale/ppsf-by-state
curl http://localhost:8095/realestate/v1/agents/top
```

## DBeaver connection to Spark

After flipping `spark.thrift.enabled=true` in the SparkSQL service and restarting:

- Driver: **Apache Hive** (download Hive JDBC 4.0.x from the Hive site or via DBeaver's driver manager)
- URL: `jdbc:hive2://localhost:10000/default`
- User: `hive` / Pass: anything (auth disabled by default)

You can then query the same views (`a_forsale_ppsf_by_state`, etc.) directly from DBeaver.

## Notes & known limitations

- Currency conversion (EUR rentals → USD) is a constant `1.08` in `SparkSQL_OLAP.sql`; replace with a join against a FX rates table if needed.
- NYC sales (DS1, Oracle) is **not** federated into Spark SQL here — Spark would need either a JDBC link to Oracle or a CSV export. For Part 2's defense, the Oracle sales view remains available through the Part 1 dashboard.
- The Mongo Spark Connector requires `mongo-spark-connector_2.13` to match the Scala version of Spark 3.5 (`_2.13`). If you upgrade Spark, bump the connector version too.
- Spark on Java 17 needs the `--add-opens` flags baked into each `pom.xml`'s `spring-boot-maven-plugin` config. Don't strip them or startup will throw `IllegalAccessError`.
