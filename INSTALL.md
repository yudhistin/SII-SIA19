# SII-SIA19 — Step-by-Step Setup Guide

Welcome to the **Integrated Real Estate Market Analysis System** project!
This guide is written for colleagues who are not deeply familiar with Docker or databases.
Just follow every step in order and you will have the full system running.

---

## Part 0 — What You Need to Install First

Install all four tools **before doing anything else**. All are free.

---

### 0.1 Docker Desktop
Runs all six databases/services automatically inside isolated containers — no manual database installation needed.

1. Go to https://www.docker.com/products/docker-desktop/
2. Download the **Windows** installer and run it.
3. During installation, accept the option to **enable WSL 2** if prompted (Windows Subsystem for Linux). Restart your computer if asked.
4. After reboot, open Docker Desktop from the Start Menu and wait until the whale icon in the taskbar stops animating (about 30 seconds). That means Docker is ready.

---

### 0.2 Git
Lets you download ("clone") the project from GitHub.

1. Go to https://git-scm.com/download/win
2. Download and run the installer, accepting all default options.
3. Verify: open a new Command Prompt (`Win+R` → type `cmd` → Enter) and run:
   ```
   git --version
   ```
   You should see something like `git version 2.x.x`.

---

### 0.3 JDK 17 (Java Development Kit)
The Java microservices in Part 2 require exactly Java **17**. Do not install 11 or 21.

1. Go to https://adoptium.net/temurin/releases/?version=17
2. Choose **Windows**, **x64**, **JDK**, installer (`.msi`). Download and run it.
3. During installation, enable the option **"Set JAVA_HOME variable"** if shown.
4. Verify — open a new Command Prompt and run:
   ```
   java -version
   ```
   You should see `openjdk version "17.x.x"`.

---

### 0.4 Apache Maven
Maven builds and runs the Java projects.

1. Go to https://maven.apache.org/download.cgi
2. Under **"Binary zip archive"** download the latest `apache-maven-3.x.x-bin.zip`.
3. Extract the zip to a permanent location, for example `C:\apache-maven\`.
4. Add Maven to your `PATH` so you can run `mvn` from any Command Prompt:
   - Press `Win+S`, search for **"Edit the system environment variables"**, open it.
   - Click **"Environment Variables…"**
   - Under **"System variables"** find `Path`, select it, click **Edit**.
   - Click **New** and add the path to Maven's `bin` folder, e.g. `C:\apache-maven\bin`.
   - Click **OK** on all dialogs.
5. Verify — open a **new** Command Prompt and run:
   ```
   mvn -version
   ```
   You should see `Apache Maven 3.x.x`.

---

### 0.5 IntelliJ IDEA (Community Edition)
The IDE used to open and run the Java microservices.

1. Go to https://www.jetbrains.com/idea/download/
2. Download the **Community Edition** (free). Run the installer with all default options.

---

### 0.6 Oracle SQL Developer
A graphical tool needed for loading data into Oracle (Part 1 only).

1. Go to https://www.oracle.com/tools/downloads/sqldev-downloads.html
2. Download the **"Windows 64-bit with JDK 17 included"** version.
3. Extract the zip to any folder (e.g. `C:\sqldeveloper\`). No installation step needed.
4. Run `sqldeveloper.exe` inside that folder.

---

## Part 1 — Clone the Repository

Open Command Prompt and run:

```cmd
git clone https://github.com/yudhistin/SII-SIA19.git
cd SII-SIA19
```

You now have the project in a folder called `SII-SIA19`.
**Every command in this guide must be run from inside that folder.**

---

## Part 2 — Start All 6 Database Containers

### 2.1 Create the environment file

```cmd
copy .env.example .env
```

You do not need to change anything — the default values work for local use.

### 2.2 Start everything with one command

```cmd
docker compose up -d
```

> **First run only:** Docker will download ~3 GB of images. This can take 10–20 minutes depending on your internet speed. It only happens once.

This command starts six containers:

| Container | Port(s) | What it is |
|---|---|---|
| `oracle-xe-21c` | 1521 | Oracle XE 21c database |
| `postgresql-container` | 5432 | PostgreSQL 14 database |
| `postgrest` | 3000 | REST API layer over PostgreSQL |
| `mongodb-6.0` | 27017 | MongoDB 6.0 database |
| `restheart` | 8080 | REST API layer over MongoDB |
| `neo4j` | 7474, 7687 | Neo4j graph database |

### 2.3 Verify all containers are running

```cmd
docker ps
```

All 6 should show **`Up`** in the STATUS column.
If any shows **`Exited`**, wait 30 seconds and run `docker ps` again (Oracle in particular takes 2–3 minutes to initialize).

### 2.4 PostgreSQL and MongoDB load their data automatically

On the very first boot, the `postgresql-container` and `mongodb-6.0` containers run built-in initialization scripts that load all the CSV/JSON data. You do **not** need to do anything manually for these two.

To confirm the data loaded correctly:
```cmd
docker logs postgresql-container 2>&1 | findstr "hosts_loaded\|listings_loaded\|Done"
docker logs mongodb-6.0 2>&1 | findstr "docs:\|Done"
```

You should see row counts printed. If the logs say `"not found - skip seeding"`, see the Troubleshooting section at the bottom.

---

## Part 3 — Load Oracle Data (Manual — One Time)

Oracle requires you to run SQL scripts manually.

### 3.1 Wait for Oracle to be ready

Oracle takes 2–3 minutes to fully start. Run this command and wait until you see `DATABASE IS READY TO USE!`:

```cmd
docker logs -f oracle-xe-21c
```

Press `Ctrl+C` to stop following the log once you see that message.

### 3.2 Connect to Oracle in SQL Developer

Open SQL Developer and create a **new connection** (click the green `+` icon):

| Field | Value |
|---|---|
| Name | `SYS_Local` |
| Username | `SYS` |
| Password | `OraclePass123` |
| Role | `SYSDBA` ← important, change from default |
| Connection Type | `Basic` |
| Hostname | `localhost` |
| Port | `1521` |
| Service Name | `XEPDB1` ← use **Service Name**, not SID |

Click **Test** — it should say *"Status: Success"*. Then click **Connect**.

### 3.3 Run the full Oracle setup script

1. In SQL Developer, go to **File → Open** and open:
   `1_Data_Sources\00_DS_ORCL_Setup.sql`
2. Press **F5** (Run Script — this runs the whole file, not just one line).
3. Wait for it to finish. The output panel will show INSERT counts for each borough.

This script creates the `FDBO` user, all tables, and loads all NYC property sales data from the CSV files.

### 3.4 Create a connection as FDBO

Create a second connection in SQL Developer:

| Field | Value |
|---|---|
| Name | `FDBO_Local` |
| Username | `FDBO` |
| Password | `fdbo` |
| Role | `default` |
| Hostname | `localhost` |
| Port | `1521` |
| Service Name | `XEPDB1` |

Click **Test**, then **Connect**.

### 3.5 Run the Access Model scripts (as SYS_Local)

Switch back to the `SYS_Local` worksheet. Open and run each file below with **F5** — wait for each to complete before running the next:

1. `2_Access_Model\26_AM_POSTGREST_Rentals_View.sql`
2. `2_Access_Model\28_AM_RESTHeart_MongoDB_View.sql`
3. `2_Access_Model\29_AM_Neo4J_View.sql`

Then switch to the `FDBO_Local` worksheet and run:

4. `2_Access_Model\21_AM_ORCL_Sales_View.sql`
5. `2_Access_Model\23_AM_CSV_ExternalTable_View.sql`
6. `2_Access_Model\27_AM_FEDERATED_View.sql`
7. `3_Integration_Model\31_OLAP_Multidimensional_Analytical.sql`

---

## Part 4 — Load Neo4j Data (Manual — One Time)

### 4.1 Open the Neo4j Browser

Go to: **http://localhost:7474**

Log in with:
- Username: `neo4j`
- Password: `test1234`

### 4.2 Paste and run the Cypher script

1. Open the file `1_Data_Sources\18_DS_Neo4J_GeoHierarchy.cypher` in Notepad.
2. Select all (`Ctrl+A`) and copy (`Ctrl+C`).
3. Click inside the **command box** at the top of the Neo4j Browser (where it says `neo4j$`).
4. Paste with `Ctrl+V` and press **Ctrl+Enter** to run.

You should see a graph of nodes and relationships appear. The text at the top of the result will show how many nodes were created.

---

## Part 5 — Quick Sanity Check

Before starting the Java services, confirm the REST APIs are working.
Open your browser and visit these URLs — each should return JSON text:

| URL | What you should see |
|---|---|
| http://localhost:3000/listing?limit=2 | 2 Airbnb rental listings |
| http://localhost:8080/realestate/forsale?pagesize=2&rep=s | 2 for-sale listings |
| http://localhost:7474 | Neo4j login page |

---

## Part 6 — Set Up IntelliJ for the Java Microservices

### 6.1 Tell IntelliJ which JDK to use

1. Open IntelliJ IDEA.
2. Go to **File → Project Structure** (or press `Ctrl+Alt+Shift+S`).
3. Click **SDKs** in the left panel.
4. Click **+** → **Add JDK**.
5. Navigate to your JDK 17 folder (e.g. `C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot\`).
6. Click **OK** on all dialogs.

### 6.2 Import the five Maven modules

In IntelliJ, go to **File → Open** and open each of the five project folders **one by one**.
IntelliJ will ask *"Trust and open Maven project?"* — always click **Trust Project**.

| Folder to open (relative to repo root) | Port |
|---|---|
| `Part2_DSA\1_Access_Layer\DSA_DOC_XLSx` | 8091 |
| `Part2_DSA\1_Access_Layer\DSA_SQL_JPA_Postgres` | 8092 |
| `Part2_DSA\1_Access_Layer\DSA_NoSQL_MongoDB` | 8093 |
| `Part2_DSA\2_Integration_Layer\DSA-SparkSQL-Service` | 8094 |
| `Part2_DSA\3_WEB_Layer\DSA_WEB_RESTService` | 8095 |

Wait for the **Maven sync** to finish in each window (watch the progress bar at the very bottom of IntelliJ). It downloads all Java dependencies automatically.

---

## Part 7 — Run the Microservices (in this exact order)

Each service runs in its own IntelliJ window. **Start them one at a time.**
Wait for each to print `Started ... in X.X seconds` in the console before starting the next.

### How to start a service in IntelliJ
For each project window:
1. Open the **Maven** tool panel: `View → Tool Windows → Maven`
2. Expand: `Plugins → spring-boot → spring-boot:run`
3. Double-click **`spring-boot:run`**

---

### Service 1 — DSA_DOC_XLSx (port 8091)
Serves the FRED macro indicator CSV data.

Start it in the `DSA_DOC_XLSx` IntelliJ window.

✅ Ready when you see: `Started DSA_DOC_XLSx in X.X seconds`

Test: http://localhost:8091/api/macro

---

### Service 2 — DSA_SQL_JPA_Postgres (port 8092)
Serves Airbnb rental listing data from PostgreSQL.

Start it in the `DSA_SQL_JPA_Postgres` IntelliJ window.

✅ Ready when you see: `Started DSA_SQL_JPA_Postgres in X.X seconds`

Test: http://localhost:8092/api/listings?size=5

---

### Service 3 — DSA_NoSQL_MongoDB (port 8093)
Serves Realtor.com for-sale listings from MongoDB.

Start it in the `DSA_NoSQL_MongoDB` IntelliJ window.

✅ Ready when you see: `Started DSA_NoSQL_MongoDB in X.X seconds`

Test: http://localhost:8093/api/forsale?size=5

---

### Service 4 — DSA-SparkSQL-Service (port 8094)
Runs Apache Spark SQL and federates all data sources into analytical views.

Start it in the `DSA-SparkSQL-Service` IntelliJ window.

> ⚠️ This service takes **60–90 seconds** to start because it launches an embedded Spark engine.
> Many lines of log output are completely normal. Wait for the final `Started` message.

✅ Ready when you see: `Started DSA-SparkSQL-Service in X.X seconds`

Test: http://localhost:8094/sql/tables

---

### Service 5 — DSA_WEB_RESTService (port 8095)
The final REST API that exposes all analytical results.

Start it in the `DSA_WEB_RESTService` IntelliJ window.

✅ Ready when you see: `Started DSA_WEB_RESTService in X.X seconds`

Test: http://localhost:8095/realestate/v1/forsale/ppsf-by-state

---

## Part 8 — Final Verification

Once all 5 services are running, open your browser and confirm these return data:

```
http://localhost:8095/realestate/v1/forsale/ppsf-by-state
http://localhost:8095/realestate/v1/agents/top
```

If you see JSON with real estate data — you are done! 🎉

---

## Stopping and Restarting

**Stop Java services:** press the red ■ square in each IntelliJ console, or press `Ctrl+C` in each terminal.

**Stop Docker containers** (data is preserved):
```cmd
docker compose down
```

**Restart everything later:**
```cmd
docker compose up -d
```
Then re-run the 5 services in IntelliJ (Part 7).

---

## Troubleshooting

### Oracle: "Connection refused" or "Listener refused the connection"
Oracle takes 2–3 minutes to initialize. Run `docker logs -f oracle-xe-21c` and wait for `DATABASE IS READY TO USE!` before trying to connect from SQL Developer.

### Oracle: Service Name `XEPDB1` not working
Try `XE` as the Service Name instead, or switch to SID mode and type `XE`.

### PostgreSQL/MongoDB: tables are empty
Run:
```cmd
docker logs postgresql-container 2>&1 | findstr "init\|Done\|ERROR"
docker logs mongodb-6.0 2>&1 | findstr "init\|Done\|ERROR"
```
If the logs say **"not found - skip seeding"**, the data files were missing when Docker first started. Fix it by wiping the volumes and restarting (the `-v` flag removes stored data so init scripts run fresh):
```cmd
docker compose down -v
docker compose up -d
```
Wait 3–4 minutes, then check logs again.

### SparkSQL service crashes with "Path does not exist" or "No such file"
The macro CSV path could not be resolved automatically. Open the file:
```
Part2_DSA\2_Integration_Layer\DSA-SparkSQL-Service\src\main\resources\application.yml
```
Find the line starting with `macro-path:` and replace it with the **full absolute path** to the file on your computer, using forward slashes. Example:
```yaml
macro-path: file:///C:/Users/YourName/SII-SIA19/1_Data_Sources/13_DS_CSV_MacroIndicators.csv
```
Save the file and restart the service.

### IntelliJ: "Java version" build errors
Go to **File → Project Structure → Project** and set the **SDK** dropdown to your JDK 17 installation.
Also check **File → Project Structure → Modules**: the **Language level** on each module should be `17`.

### "Port already in use" when starting a Java service
Another program is occupying that port. Find and stop it, or restart your computer to free all ports.

### Maven command not found (`mvn` not recognized)
Close all Command Prompt windows and open a new one — the PATH change only takes effect in new windows. If it still fails, re-follow step 0.4 and make sure the path ends in `\bin`.

---

## Quick Reference — All Ports & Credentials

| Port | Service | Username | Password |
|---|---|---|---|
| 1521 | Oracle XE | `SYS` or `FDBO` | `OraclePass123` / `fdbo` |
| 5432 | PostgreSQL | `postgres` | `pg` |
| 3000 | PostgREST | *(none — public)* | — |
| 27017 | MongoDB | *(none — no auth)* | — |
| 8080 | RESTHeart | `admin` | `secret` |
| 7474 | Neo4j Browser | `neo4j` | `test1234` |
| 7687 | Neo4j Bolt | `neo4j` | `test1234` |
| 8091 | DSA_DOC_XLSx | — | — |
| 8092 | DSA_SQL_JPA_Postgres | — | — |
| 8093 | DSA_NoSQL_MongoDB | — | — |
| 8094 | DSA-SparkSQL-Service | — | — |
| 8095 | DSA_WEB_RESTService | — | — |
