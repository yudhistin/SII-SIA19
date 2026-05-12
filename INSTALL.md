# Step-by-Step Installation Guide

Welcome to the **SII-SIA19** project! This guide is designed to help you set up the environment and run the application on your machine from scratch. It is written to be as clear and beginner-friendly as possible.

The project is split into two parts:
* **Part 1** is based on Oracle Database, integrating data from different databases directly inside Oracle.
* **Part 2** is a modern microservices architecture built with Java (Spring Boot) and Apache Spark.

---

## Prerequisites: Applications You Need to Install

Before running the project, you need to install a few essential applications:

### 1. Docker Desktop
Docker is used to run our databases (Oracle, PostgreSQL, MongoDB, Neo4j) without installing them directly on your system. It keeps everything clean and isolated.
* **Download:** Go to the [Docker Desktop Download Page](https://www.docker.com/products/docker-desktop/) and download the installer.
* **Install:** Run the installer. Ensure WSL 2 (Windows Subsystem for Linux) is enabled if you are on Windows. You may need to restart your computer.
* **Verify:** Open Docker Desktop and ensure it is running (the whale icon in your system tray should be green or indicate it's running).

### 2. Oracle SQL Developer (Required for Part 1)
This is a graphical tool used to connect to the Oracle Database.
* **Download:** Go to the [Oracle SQL Developer Download Page](https://www.oracle.com/tools/downloads/sqldev-downloads.html). Choose the "Windows Includes JDK" version if you are on Windows.
* **Install:** Simply extract the downloaded zip file to a folder (e.g., `C:\Program Files\sqldeveloper`).
* **Run:** Open the `sqldeveloper.exe` file inside that folder.

### 3. Java Development Kit (JDK) 17 (Required for Part 2)
You need Java 17 to compile and run the backend microservices.
* **Download:** Use [Eclipse Temurin JDK 17](https://adoptium.net/temurin/releases/?version=17).
* **Install:** Download the installer for your operating system and follow the standard installation steps.
* **Verify:** Open a terminal (Command Prompt or PowerShell) and type `java -version`. It should print `openjdk version "17.x.x"`.

### 4. Apache Maven (Required for Part 2)
Maven is a build automation tool used for our Java projects.
* **Download:** Go to the [Maven Download Page](https://maven.apache.org/download.cgi) and download the `Binary zip archive`.
* **Install:** Extract the folder to a location on your computer (e.g., `C:\Apache\maven`).
* **Environment Variable:** Add the `bin` folder (e.g., `C:\Apache\maven\bin`) to your system's `PATH` environment variable.
* **Verify:** Open a new terminal and type `mvn -version`.

### 5. IntelliJ IDEA (Required for Part 2)
IntelliJ is the recommended Integrated Development Environment (IDE) for writing and running our Java code.
* **Download:** Go to the [IntelliJ IDEA Download Page](https://www.jetbrains.com/idea/download/). The **Community Edition** is free and perfectly fine.
* **Install:** Run the installer with the default options.

---

## Setting up the Databases (Both Parts)

Both parts of the project require the databases to be running. We use Docker to make this easy.

1. **Open a Terminal:** Open Command Prompt or PowerShell and navigate to the folder where you downloaded this project (`SII-SIA19`).
2. **Start the Containers:** Type the following command and press Enter:
   ```bash
   docker compose up -d
   ```
   *(Note: This will download the databases the very first time you run it, which might take a few minutes. Grab a coffee!)*
3. **Verify:** Open Docker Desktop. You should see a group called `sii-sia19` with several containers running inside it (oracle, postgres, mongo, neo4j, etc.).

---

## How to Run Part 1: Oracle Federation

Part 1 relies on Oracle Database. The data files (like CSVs) have already been mapped automatically via the `docker-compose.yml` file, so you do not need to manually copy them into the container! They are loaded directly from the `1_Data_Sources` folder on your computer.

### Step 1: Connect to Oracle as the SYS user
We first need to connect as the administrator (`SYS`) to create our project user (`FDBO`).

1. Open **Oracle SQL Developer**.
2. Click the green **"+"** icon in the top left (under "Connections") to create a new connection.
3. Fill in the details exactly like this:
   * **Name:** `SYS_Local` (or whatever you prefer)
   * **Username:** `SYS`
   * **Password:** `OraclePass123` (this is the default password from our Docker setup)
   * **Role:** `SYSDBA` (Important! Change this from default to SYSDBA)
   * **Connection Type:** `Basic`
   * **Hostname:** `localhost`
   * **Port:** `1521`
   * **Service Name:** `XEPDB1` (Important! Do NOT use SID. Check Service Name and type `XEPDB1`)
4. Click **Test**. It should say "Status: Success" in the bottom left.
5. Click **Connect**.

### Step 2: Create the FDBO User
1. In the SQL worksheet that opens for your `SYS_Local` connection, copy and paste the entire contents of the file located at:
   `SII-SIA19 \ 1_Data_Sources \ 00_RESET_FDBO_local.sql`
2. Select all the text and click the **Run Script** button (the icon that looks like a page with a green play button, or press `F5`).
3. This script will safely create the `FDBO` user with the password `fdbo` and grant it the necessary permissions.

### Step 3: Connect as the FDBO User
Now that the project user exists, we need to log in as that user to load the tables.

1. Click the green **"+"** icon again to create a second connection.
2. Fill in the details:
   * **Name:** `FDBO_Local`
   * **Username:** `FDBO`
   * **Password:** `fdbo`
   * **Role:** `default`
   * **Connection Type:** `Basic`
   * **Hostname:** `localhost`
   * **Port:** `1521`
   * **Service Name:** `XEPDB1`
3. Click **Test** (should succeed), then **Connect**.

### Step 4: Run the Setup Scripts
Make sure you are in the `FDBO_Local` worksheet. You must run the SQL scripts in numerical order to load the tables and views. For each script below, open it, copy the contents, paste it into the `FDBO_Local` worksheet, and click **Run Script** (`F5`):

1. Run `1_Data_Sources \ 11_DS_ORCL_Schema_Sales.sql`
2. Run `2_Access_Model \ 21_AM_ORCL_Sales_View.sql`
3. Run `2_Access_Model \ 23_AM_CSV_ExternalTable_View.sql`
4. Run `2_Access_Model \ 26_AM_POSTGREST_Rentals_View.sql`
5. Run `2_Access_Model \ 27_AM_FEDERATED_View.sql`
6. Run `2_Access_Model \ 28_AM_RESTHeart_MongoDB_View.sql`
7. Run `2_Access_Model \ 29_AM_Neo4J_View.sql`
8. Finally, run the analytical model: `3_Integration_Model \ 31_OLAP_Multidimensional_Analytical.sql`

If you ran them in order without errors, Part 1 is successfully installed and the federated data is ready!

---

## How to Run Part 2: Java Microservices & Spark

Once the databases are running via Docker (as done in the "Setting up the Databases" section above), follow these steps:

### Step 1: Open the Project in IntelliJ
1. Open IntelliJ IDEA.
2. Click on **Open** and select the root folder of this project (`SII-SIA19`).
3. Wait a moment for IntelliJ to index the files and recognize the Maven projects (you should see a little "M" icon on the `pom.xml` files).

### Step 2: Run the Microservices
The project consists of several microservices that need to be started in a specific order. You can either run them directly from IntelliJ (by finding the `Application.java` file for each and clicking the green "Play" button) or by using the terminal.

If using the terminal, open a new terminal window for **each** of the following commands (from the root project directory):

**A. Access Layer Services (Start these first):**
1. **DSA_DOC_XLSx:**
   ```bash
   cd Part2_DSA/1_Access_Layer/DSA_DOC_XLSx
   mvn spring-boot:run
   ```
2. **DSA_SQL_JPA_Postgres:**
   ```bash
   cd Part2_DSA/1_Access_Layer/DSA_SQL_JPA_Postgres
   mvn spring-boot:run
   ```
3. **DSA_NoSQL_MongoDB:**
   ```bash
   cd Part2_DSA/1_Access_Layer/DSA_NoSQL_MongoDB
   mvn spring-boot:run
   ```

**B. Integration Layer (Wait until the above 3 are fully started):**
4. **DSA-SparkSQL-Service:**
   ```bash
   cd Part2_DSA/2_Integration_Layer/DSA-SparkSQL-Service
   mvn spring-boot:run
   ```

**C. Web REST Service (Wait until SparkSQL is fully started):**
5. **DSA_WEB_RESTService:**
   ```bash
   cd Part2_DSA/3_WEB_Layer/DSA_WEB_RESTService
   mvn spring-boot:run
   ```

### Step 3: Verify Everything is Working
Once all 5 Java services are running, you can test the system by opening your web browser and navigating to:
* `http://localhost:8095/realestate/v1/forsale/ppsf-by-state`
* `http://localhost:8095/realestate/v1/agents/top`

If you see data being returned in the browser, congratulations! Part 2 is successfully installed and running.

---

### Shutting Down
To stop the Java services, you can press `Ctrl+C` in the terminals running them, or click the red "Stop" square in IntelliJ. To stop the databases, run this command in the project root terminal:
```bash
docker compose down
```