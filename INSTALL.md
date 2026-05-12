# SII-SIA19 — Complete Setup Guide (Step by Step)

> **Read this first.**
> This guide is written so that even someone who has never used a database or a terminal can follow it.
> Every single step is numbered. Do them in order. Do not skip anything.
>
> If something says "open a Command Prompt", that means:
> press **Win + R** on your keyboard, type `cmd`, and press **Enter**.
> A black window will appear — that is the Command Prompt.

---

## CHAPTER 0 — Install Everything You Need

You need to install seven programs before you can run this project.
They are all free. This chapter covers each one.

---

### 0.1 — Docker Desktop

**What it is:** Docker runs all the databases for this project inside "containers" — think of them as tiny virtual computers living inside your PC. You do not need to install Oracle, PostgreSQL, MongoDB or Neo4j manually.

**How to install:**
1. Go to: https://www.docker.com/products/docker-desktop/
2. Click the big blue **"Download for Windows"** button.
3. Run the downloaded file (`Docker Desktop Installer.exe`).
4. During installation, when it asks about **WSL 2**, say **Yes** / **Enable**. This is Windows Subsystem for Linux and Docker needs it.
5. Your computer will probably restart after installation. Let it.
6. After restart, open **Docker Desktop** from the Start Menu (search for "Docker").
7. Wait until the whale icon in the bottom-right corner of your taskbar **stops moving**. That means Docker is ready. It takes about 30 seconds.

**How to check it worked:** Open a Command Prompt and type:
```
docker --version
```
You should see something like `Docker version 26.x.x`. If you see an error, Docker is not running — open Docker Desktop and try again.

---

### 0.2 — Git

**What it is:** Git lets you download this project from the internet (GitHub) onto your computer.

**How to install:**
1. Go to: https://git-scm.com/download/win
2. Click the link for the **64-bit Git for Windows Setup**.
3. Run the installer. Click **Next** through all the steps — the default options are all fine.

**How to check it worked:** Open a new Command Prompt and type:
```
git --version
```
You should see something like `git version 2.x.x`.

---

### 0.3 — JDK 17 (Java)

**What it is:** Java is the programming language the project's microservices (Part 2) are written in. JDK 17 is the specific version this project requires. **Do not install version 11 or 21 — only 17.**

**How to install:**
1. Go to: https://adoptium.net/temurin/releases/?version=17
2. Set the filters to: **Operating System = Windows**, **Architecture = x64**, **Package Type = JDK**, **Version = 17**.
3. Download the `.msi` installer file.
4. Run it. During installation, **make sure the option "Set JAVA_HOME variable" is turned ON** (it shows as a hard drive icon in the installer — click it and choose "Will be installed on local hard drive"). This is important.
5. Finish the installation.

**How to check it worked:** Open a **new** Command Prompt and type:
```
java -version
```
You should see `openjdk version "17.x.x"`. If it says version 11 or 21, you have the wrong one.

---

### 0.4 — Apache Maven

**What it is:** Maven is a tool that downloads all the Java code libraries this project needs, and runs the Java microservices. Think of it as an automatic assistant that installs everything your Java programs need.

**How to install:**
1. Go to: https://maven.apache.org/download.cgi
2. Under the **"Files"** table, find the row for **"Binary zip archive"** and click the `.zip` link to download.
3. Once downloaded, **extract** (unzip) the folder. Right-click the zip → **Extract All**. Choose a permanent location, for example `C:\apache-maven\`. After extraction you should see a folder like `C:\apache-maven\apache-maven-3.x.x\`.
4. Now you need to tell Windows where Maven is. This is called adding it to the PATH:
   - Press **Win + S** and search for: **Edit the system environment variables**. Open it.
   - A window called "System Properties" opens. Click the **"Environment Variables…"** button at the bottom.
   - In the bottom panel ("System variables"), scroll down to find **Path**. Click it once to select it, then click **Edit**.
   - Click **New** on the right side.
   - Type the path to Maven's `bin` folder. Example: `C:\apache-maven\apache-maven-3.x.x\bin`
     *(Replace `3.x.x` with the actual version number from your extracted folder.)*
   - Click **OK** on all three windows.

**How to check it worked:** Open a **new** Command Prompt and type:
```
mvn -version
```
You should see `Apache Maven 3.x.x`. If it says `'mvn' is not recognized`, the PATH step above was not done correctly — try it again.

---

### 0.5 — IntelliJ IDEA (Community Edition)

**What it is:** IntelliJ IDEA is a program that lets you open, read, and run the Java microservice projects. The Community Edition is completely free.

**How to install:**
1. Go to: https://www.jetbrains.com/idea/download/
2. Scroll down to **Community Edition** and click **Download**.
3. Run the installer. On the "Installation Options" screen, tick the box **"Add 'Open Folder as Project'"** — this makes it easier to open projects later.
4. Finish and restart your computer if asked.

---

### 0.6 — Oracle SQL Developer

**What it is:** SQL Developer is a graphical program for connecting to Oracle Database and running SQL scripts. It looks like a window where you can type database commands and see results.

**How to install:**
1. Go to: https://www.oracle.com/tools/downloads/sqldev-downloads.html
2. Under "Downloads", find the row that says **"Windows 64-bit with JDK 17 included"** and click **Download**. (You may need to create a free Oracle account and log in — it only takes a minute.)
3. Once downloaded, you get a `.zip` file. **Extract** it anywhere, for example `C:\sqldeveloper\`.
4. To open SQL Developer, go into that extracted folder and double-click **`sqldeveloper.exe`**.
   *(You may want to right-click it and choose "Pin to taskbar" for easy access later.)*

---

### 0.7 — Python 3

**What it is:** Python is needed for two things in this project: running a small "go-between" server that fixes browser security issues (the CORS proxy), and serving the dashboard webpage.

**How to install:**
1. Go to: https://www.python.org/downloads/
2. Click the big yellow **"Download Python 3.x.x"** button.
3. Run the downloaded file. **IMPORTANT:** On the very first screen of the installer, tick the box at the bottom that says **"Add Python to PATH"**. If you skip this, Python will not work from the Command Prompt.
4. Click **Install Now**.

**How to check it worked:** Open a **new** Command Prompt and type:
```
python --version
```
You should see `Python 3.x.x`.

---

### 0.8 — ORDS (Oracle REST Data Services)

**What it is:** ORDS is a small server program made by Oracle. It sits between the Oracle database and the web browser, turning database results into web links (REST endpoints) that the dashboard can read. Without ORDS, the dashboard cannot get any data from Oracle.

**How to install:**
1. Go to: https://www.oracle.com/database/sqldeveloper/technologies/db-actions/download/
2. Find **"Oracle REST Data Services"** and click **Download**. (You may need to log in with your Oracle account from step 0.6.)
3. You get a `.zip` file. Extract it to a permanent folder, for example `C:\ords\`.
   Inside you will see a file called `ords.jar` (or just `ords`) and some folders.
4. Add ORDS to your PATH the same way you added Maven (step 0.4):
   - Go to **Edit the system environment variables → Environment Variables → System variables → Path → Edit → New**
   - Add the path to the ORDS folder, e.g. `C:\ords\`
   - Click OK on all windows.

**How to check it worked:** Open a **new** Command Prompt and type:
```
ords --version
```
You should see something like `Oracle REST Data Services 24.x.x`.

---

## CHAPTER 1 — Download the Project

Open a Command Prompt and run these two commands. The first downloads the project, the second moves you into the project folder:

```cmd
git clone https://github.com/yudhistin/SII-SIA19.git
cd SII-SIA19
```

A new folder called `SII-SIA19` now exists on your computer. From this point on, **every command in this guide must be run from inside that folder.** If you close the Command Prompt and open a new one later, type `cd SII-SIA19` (or the full path) to get back there.

---

## CHAPTER 2 — Start All Six Database Containers

### Step 2.1 — Create your configuration file

The databases need some passwords. We have prepared an example file for you. Copy it with this command:

```cmd
copy .env.example .env
```

You do not need to change anything inside this file. The default values work.

### Step 2.2 — Start the databases

Run this one command:

```cmd
docker compose up -d
```

What happens:
- Docker downloads the database software for all six containers. **The very first time this runs, it will download about 3 GB of files. This can take 10 to 30 minutes depending on your internet speed.** Grab a coffee. It only ever does this once.
- After the download, all six databases start automatically.

The six services that start are:

| Name | Port | What it does |
|---|---|---|
| `oracle-xe-21c` | 1521 | Oracle Database (holds NYC property sales data) |
| `postgresql-container` | 5432 | PostgreSQL (holds Amsterdam rental listings) |
| `postgrest` | 3000 | Makes PostgreSQL data available as web links |
| `mongodb-6.0` | 27017 | MongoDB (holds 200,000 US for-sale listings) |
| `restheart` | 8080 | Makes MongoDB data available as web links |
| `neo4j` | 7474 | Neo4j graph database (holds geographic data) |

### Step 2.3 — Check everything started

```cmd
docker ps
```

You should see 6 rows, each showing **`Up`** in the STATUS column. If any row shows `Exited`, wait one more minute and run `docker ps` again — Oracle is especially slow to start (it takes 2–3 minutes).

### Step 2.4 — PostgreSQL and MongoDB load data by themselves

Good news: the two hardest databases (PostgreSQL and MongoDB) load all their data **automatically** the first time they start. You do not need to do anything.

To confirm it worked, run:
```cmd
docker logs postgresql-container 2>&1 | findstr /i "loaded Done ERROR"
docker logs mongodb-6.0 2>&1 | findstr /i "docs: Done ERROR"
```
You should see row counts and the word "Done" — not "ERROR". If you see "not found - skip seeding", jump to the Troubleshooting section at the end of this guide.

---

## CHAPTER 3 — Load Oracle Data (Manual — One Time Only)

Oracle needs you to run scripts manually. Follow these steps carefully.

### Step 3.1 — Wait for Oracle to be ready

Oracle takes 2–3 minutes to fully start. Open a Command Prompt and run:
```cmd
docker logs -f oracle-xe-21c
```
Watch the lines scroll by. **Wait until you see the line:**
```
DATABASE IS READY TO USE!
```
Then press **Ctrl+C** to stop watching the logs. Only now can you connect.

### Step 3.2 — Open SQL Developer and connect as SYS

1. Open SQL Developer (double-click `sqldeveloper.exe` from step 0.6).
2. In the left panel under "Connections", click the **green plus icon (+)** to create a new connection.
3. Fill in these exact values:

   | Field | Value |
   |---|---|
   | Name | `SYS_Local` |
   | Username | `SYS` |
   | Password | `OraclePass123` |
   | Role | `SYSDBA` ← **change this from the default!** |
   | Connection Type | `Basic` |
   | Hostname | `localhost` |
   | Port | `1521` |
   | Service Name radio button | selected |
   | Service Name | `XEPDB1` |

4. Click **Test** at the bottom of the dialog. It should say **"Status: Success"** in the bottom-left corner.
5. Click **Connect**.
   A worksheet (text area) opens — this is where you will paste and run SQL commands.

### Step 3.3 — Run the main Oracle setup script

1. In SQL Developer, go to **File → Open** (or press Ctrl+O).
2. Navigate to the project folder and open: `1_Data_Sources\00_DS_ORCL_Setup.sql`
3. The script opens in the worksheet. Press **F5** to run it.
   *(F5 = "Run Script" — it runs the entire file. Do not press F9, which only runs one line.)*
4. Watch the output panel at the bottom. It will show INSERT counts for Manhattan, Brooklyn, Queens, the Bronx, and Staten Island. Wait until it stops scrolling.

This script creates a database user called `FDBO`, creates all the tables, and loads all the NYC property sales data.

### Step 3.4 — Create a second connection as FDBO

1. Click the green **+** icon again to create another connection.
2. Fill in:

   | Field | Value |
   |---|---|
   | Name | `FDBO_Local` |
   | Username | `FDBO` |
   | Password | `fdbo` |
   | Role | `default` |
   | Connection Type | `Basic` |
   | Hostname | `localhost` |
   | Port | `1521` |
   | Service Name | `XEPDB1` |

3. Click **Test** (should say Success), then **Connect**.

### Step 3.5 — Run the remaining scripts

You need to run several more scripts. For each one:
- Go to **File → Open**, open the file
- Make sure the correct connection is active (the tab at the top shows which connection you're in)
- Press **F5** to run
- Wait for it to finish before opening the next file

Run these files in order, **using the `SYS_Local` connection**:

1. `2_Access_Model\26_AM_POSTGREST_Rentals_View.sql`
2. `2_Access_Model\28_AM_RESTHeart_MongoDB_View.sql`
3. `2_Access_Model\29_AM_Neo4J_View.sql`

Then **switch to the `FDBO_Local` connection** (click the FDBO_Local tab) and run:

4. `2_Access_Model\21_AM_ORCL_Sales_View.sql`
5. `2_Access_Model\23_AM_CSV_ExternalTable_View.sql`
6. `2_Access_Model\27_AM_FEDERATED_View.sql`
7. `3_Integration_Model\31_OLAP_Multidimensional_Analytical.sql`

---

## CHAPTER 4 — Load Neo4j Data (Manual — One Time Only)

### Step 4.1 — Open the Neo4j Browser

Open your web browser (Chrome, Firefox, Edge — any of them) and go to:
**http://localhost:7474**

You will see a login screen. Enter:
- Username: `neo4j`
- Password: `test1234`

Click **Connect**.

### Step 4.2 — Copy the Cypher script

1. Open the file `1_Data_Sources\18_DS_Neo4J_GeoHierarchy.cypher` in Notepad.
   *(Right-click the file → Open with → Notepad)*
2. Press **Ctrl+A** to select everything, then **Ctrl+C** to copy.

### Step 4.3 — Paste and run in Neo4j

1. Click inside the **command input box** at the very top of the Neo4j page. It looks like a text bar with `neo4j$` on the left.
2. Press **Ctrl+V** to paste the script.
3. Press **Ctrl+Enter** to run it.

Wait about 10 seconds. You should see a graph with coloured dots (nodes) and lines (relationships) appear on screen. That means the geographic data loaded successfully.

---

## CHAPTER 5 — Set Up ORDS (The Bridge Between Oracle and the Dashboard)

ORDS is what turns Oracle database results into web links that the dashboard can display. It runs as a separate program on port **8181**.

### Step 5.1 — Configure ORDS to connect to Oracle

Open a **new** Command Prompt window. Run this command (all on one line — copy and paste it):

```cmd
ords --config C:\ords-config install --admin-user SYS --db-hostname localhost --db-port 1521 --db-servicename XEPDB1 --feature-sdw true --password-stdin
```

It will ask you for the **SYS password**. Type: `OraclePass123` and press Enter.

It will then ask about the ORDS schema password and the APEX passwords. You can press **Enter** to accept the defaults for all of them.

Wait for it to finish. When it says `Completed`, ORDS is configured.

### Step 5.2 — Enable the FDBO user for REST access

In SQL Developer, open the **FDBO_Local** connection and paste this into the worksheet, then press **F5**:

```sql
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled             => TRUE,
        p_schema              => 'FDBO',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'fdbo',
        p_auto_rest_auth      => FALSE
    );
    COMMIT;
END;
/
```

### Step 5.3 — Register the REST endpoints

Still in the **FDBO_Local** worksheet, open and run this file with F5:

```
4_WEB_Model\41_WEB_REST_Services.sql
```

This creates seven REST endpoints (web links) inside Oracle — one for each type of real estate analysis.

### Step 5.4 — Start ORDS

Go back to your Command Prompt (or open a new one) and run:

```cmd
ords --config C:\ords-config serve --port 8181
```

ORDS will start and print some startup messages. Leave this Command Prompt window open — **closing it stops ORDS**.

**How to check it worked:** Open your browser and go to:
`http://localhost:8181/ords/fdbo/realestate/v1/agents/top`

You should see a page full of JSON data (numbers and text in a structured format). If you see data, ORDS is working correctly.

---

## CHAPTER 6 — Start the Dashboard

The dashboard is a single HTML file (`4_WEB_Model/index.html`). You cannot just double-click it to open it in a browser — that causes security errors. You need to serve it through a small web server. You also need the CORS proxy running so the dashboard can talk to ORDS.

You need **two separate Command Prompt windows** open at the same time for this chapter.

### Step 6.1 — Start the CORS Proxy (Window 1)

Open a **new** Command Prompt. Navigate to the project folder, then into the WEB model folder, and start the proxy:

```cmd
cd SII-SIA19\4_WEB_Model
python cors_proxy.py
```

You will see:
```
CORS proxy: http://localhost:8182  ->  http://localhost:8181
```

**Leave this window open.** The proxy is now running. It sits invisibly in the background, fixing browser security rules so the dashboard can fetch data from ORDS. Closing this window stops it.

> **What is this proxy for?**
> Web browsers have a security rule that blocks web pages from fetching data from a different server unless that server explicitly allows it. ORDS does not add those permission headers by default. This tiny Python script sits in the middle: the dashboard asks the proxy, the proxy asks ORDS, and the proxy adds the permission headers before sending the answer back. The dashboard never even knows the proxy is there.

### Step 6.2 — Start the Web Server for the Dashboard (Window 2)

Open a **second new** Command Prompt. Navigate to the WEB model folder and start a small web server:

```cmd
cd SII-SIA19\4_WEB_Model
python -m http.server 9090
```

You will see:
```
Serving HTTP on 0.0.0.0 port 9090 ...
```

**Leave this window open too.**

> **Why can't we just double-click the HTML file?**
> When you open an HTML file directly by double-clicking, the browser treats it as a local file (`file://`). A local file is not allowed by browsers to make requests to `localhost:8182` — it's another security rule. Serving the file through a proper web server (even a tiny one like this) avoids that problem.

### Step 6.3 — Open the Dashboard

Open your browser and go to: **http://localhost:9090/index.html**

You should see the Real Estate Federated Dashboard. At the top there is a text box showing the data URL — it should already say `http://localhost:8182/ords/fdbo/realestate/v1`. Click the **"Load Data"** button (or it may load automatically). Charts and tables will appear showing NYC sales, rental yields, price per square foot by US state, and top agents.

---

## CHAPTER 7 — (Part 2 only) Open the Java Microservices in IntelliJ

Part 2 of the project uses Java microservices instead of ORDS for the API layer. You only need this chapter if you are running/demonstrating Part 2.

### Step 7.1 — Tell IntelliJ which Java version to use

1. Open IntelliJ IDEA.
2. Press **Ctrl+Alt+Shift+S** to open Project Structure.
3. In the left panel, click **SDKs**.
4. Click the **+** button → **Add JDK**.
5. A file browser opens. Navigate to where JDK 17 is installed.
   It is usually somewhere like `C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot\`.
   Select that folder and click **OK**.
6. Click **OK** to close Project Structure.

### Step 7.2 — Import the five projects

Each microservice is a separate project. In IntelliJ, go to **File → Open** and open each of these folders one by one. Each time IntelliJ asks **"Trust and open Maven project?"**, click **Trust Project**.

After opening each project, wait for IntelliJ to finish downloading dependencies (you will see a progress bar at the very bottom of the IntelliJ window — wait until it disappears before opening the next one).

| Folder to open | Port | What it does |
|---|---|---|
| `Part2_DSA\1_Access_Layer\DSA_DOC_XLSx` | 8091 | Serves the FRED macro-economic CSV data |
| `Part2_DSA\1_Access_Layer\DSA_SQL_JPA_Postgres` | 8092 | Serves the Amsterdam rental data from PostgreSQL |
| `Part2_DSA\1_Access_Layer\DSA_NoSQL_MongoDB` | 8093 | Serves the US for-sale listings from MongoDB |
| `Part2_DSA\2_Integration_Layer\DSA-SparkSQL-Service` | 8094 | Combines all sources using Apache Spark |
| `Part2_DSA\3_WEB_Layer\DSA_WEB_RESTService` | 8095 | The final REST API used by the dashboard |

### Step 7.3 — Run each service (in this exact order)

For each project window in IntelliJ:
1. Open the **Maven** side panel: go to **View → Tool Windows → Maven**.
2. In the Maven panel, expand: **Plugins → spring-boot**.
3. Double-click **`spring-boot:run`**.

Wait for the console at the bottom to print:
`Started [ServiceName] in X.X seconds`

Only then move on to the next service.

**Start them in this order:**

| Order | Service folder | Wait for this message |
|---|---|---|
| 1 | `DSA_DOC_XLSx` | `Started DSA_DOC_XLSx in X.X seconds` |
| 2 | `DSA_SQL_JPA_Postgres` | `Started DSA_SQL_JPA_Postgres in X.X seconds` |
| 3 | `DSA_NoSQL_MongoDB` | `Started DSA_NoSQL_MongoDB in X.X seconds` |
| 4 | `DSA-SparkSQL-Service` | `Started DSA-SparkSQL-Service in X.X seconds` *(takes 60–90 seconds — be patient!)* |
| 5 | `DSA_WEB_RESTService` | `Started DSA_WEB_RESTService in X.X seconds` |

### Step 7.4 — Switch the dashboard to Part 2 mode

The dashboard can work with either ORDS (Part 1) or the Java WEB service (Part 2).

Open your browser at **http://localhost:9090/index.html**.
At the top, find the URL text box. Change it from:
```
http://localhost:8182/ords/fdbo/realestate/v1
```
to:
```
http://localhost:8095/realestate/v1
```
Then click **Load Data**. The same charts will appear, now powered by Spark SQL instead of Oracle ORDS.

---

## CHAPTER 8 — How to Stop Everything

**Stop the Java services (Part 2):** Click the red square ■ in each IntelliJ console, or press **Ctrl+C** in each terminal window.

**Stop the CORS proxy and HTTP server:** Press **Ctrl+C** in the two Command Prompt windows from Chapter 6.

**Stop ORDS:** Press **Ctrl+C** in the Command Prompt window from Step 5.4.

**Stop all Docker containers** (your data is saved):
```cmd
docker compose down
```

**To start everything again later:**
```cmd
docker compose up -d
```
Then repeat Chapter 5 Step 5.4 (start ORDS), Chapter 6 (start proxy and HTTP server), and Chapter 7 Step 7.3 (start Java services in IntelliJ).

---

## CHAPTER 9 — Troubleshooting

### "Connection refused" when connecting SQL Developer to Oracle
Oracle takes 2–3 minutes to start. Open a Command Prompt and run `docker logs -f oracle-xe-21c`. Wait for the line `DATABASE IS READY TO USE!` before trying SQL Developer again. Press Ctrl+C to stop watching the logs.

### PostgreSQL or MongoDB tables are empty / "not found - skip seeding"
The data files were not in place when the containers first started. Fix:
1. Stop and remove the containers AND their stored data (the `-v` flag):
   ```cmd
   docker compose down -v
   ```
2. Start again:
   ```cmd
   docker compose up -d
   ```
3. Wait 3–4 minutes, then check: `docker logs postgresql-container`

### ORDS says "Unable to connect to Oracle"
Make sure the Oracle container is running (`docker ps` shows `oracle-xe-21c` as `Up`) and that you waited for `DATABASE IS READY TO USE!` before starting ORDS.

### Dashboard shows "Error loading data" or all zeros
Check that all three things are running at the same time: ORDS (Chapter 5), the CORS proxy (Chapter 6 Step 6.1), and the HTTP server (Chapter 6 Step 6.2). If any of the three Command Prompt windows was closed, restart it.

### SparkSQL service crashes with "Path does not exist" (Part 2)
The CSV file path could not be found automatically. Open this file in Notepad:
```
Part2_DSA\2_Integration_Layer\DSA-SparkSQL-Service\src\main\resources\application.yml
```
Find the line that starts with `macro-path:` and change it to the full path on **your** computer using forward slashes. For example:
```yaml
macro-path: file:///C:/Users/YourName/SII-SIA19/1_Data_Sources/13_DS_CSV_MacroIndicators.csv
```
Save the file and restart the service in IntelliJ.

### IntelliJ shows Java errors / red underlines everywhere
Go to **File → Project Structure → Project**. Make sure **SDK** is set to your JDK 17 installation. Then go to **Modules**, click each module, and set **Language level** to **17**. Click OK and wait for IntelliJ to re-index.

### `mvn` is not recognized in Command Prompt
You need to open a **new** Command Prompt after adding Maven to PATH. If it still does not work, repeat step 0.4 and make sure the path you added ends with `\bin`.

### `python` is not recognized in Command Prompt
You need to open a **new** Command Prompt after installing Python. If it still does not work, Python was not added to PATH — uninstall Python, then reinstall it and make sure to tick the **"Add Python to PATH"** checkbox on the first screen of the installer.

---

## Quick Reference — All Ports and Passwords

| Port | What is running there | Username | Password |
|---|---|---|---|
| 1521 | Oracle XE database | `SYS` or `FDBO` | `OraclePass123` / `fdbo` |
| 5432 | PostgreSQL database | `postgres` | `pg` |
| 3000 | PostgREST (Postgres web API) | *(no login)* | — |
| 27017 | MongoDB | *(no login)* | — |
| 8080 | RESTHeart (MongoDB web API) | `admin` | `secret` |
| 7474 | Neo4j Browser | `neo4j` | `test1234` |
| 7687 | Neo4j Bolt (driver) | `neo4j` | `test1234` |
| 8181 | ORDS (Oracle REST API) | — | — |
| 8182 | CORS Proxy (`cors_proxy.py`) | — | — |
| 9090 | Dashboard HTTP server | — | — |
| 8091 | DSA_DOC_XLSx (Part 2) | — | — |
| 8092 | DSA_SQL_JPA_Postgres (Part 2) | — | — |
| 8093 | DSA_NoSQL_MongoDB (Part 2) | — | — |
| 8094 | DSA-SparkSQL-Service (Part 2) | — | — |
| 8095 | DSA_WEB_RESTService (Part 2) | — | — |
