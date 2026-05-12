# Step-by-Step Installation Guide

Welcome to the **SII-SIA19** project! This guide is designed to help you set up the environment and run the application on your machine from scratch. Don't worry if you're not deeply familiar with all the tools—just follow these steps in order.

## Prerequisites: Applications You Need to Install

Before running the project, you need to install a few essential applications:

### 1. Java Development Kit (JDK) 17
You need Java 17 to compile and run the backend microservices.
* **Download:** Go to the [Oracle JDK 17 Download Page](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) or use [Eclipse Temurin JDK 17](https://adoptium.net/temurin/releases/?version=17).
* **Install:** Download the installer for your operating system and follow the standard installation steps. 
* **Verify:** Open a terminal (Command Prompt or PowerShell) and type `java -version`. It should print `openjdk version "17.x.x"`.

### 2. Apache Maven
Maven is a build automation tool used for our Java projects.
* **Download:** Go to the [Maven Download Page](https://maven.apache.org/download.cgi) and download the `Binary zip archive`.
* **Install:** Extract the folder to a location on your computer (e.g., `C:\Program Files\Apache\maven`). 
* **Environment Variable:** Add the `bin` folder (e.g., `C:\Program Files\Apache\maven\bin`) to your system's `PATH` environment variable.
* **Verify:** Open a new terminal and type `mvn -version`.

### 3. Docker Desktop
Docker is used to run our databases (Oracle, PostgreSQL, MongoDB, Neo4j) without installing them directly on your system.
* **Download:** Go to the [Docker Desktop Download Page](https://www.docker.com/products/docker-desktop/) and download the installer.
* **Install:** Run the installer. You might need to restart your computer and ensure WSL 2 (Windows Subsystem for Linux) is enabled if you are on Windows.
* **Verify:** Open Docker Desktop and ensure it is running (the whale icon in your system tray should be green or indicate it's running).

### 4. IntelliJ IDEA
IntelliJ is the recommended Integrated Development Environment (IDE) for writing and running our Java code.
* **Download:** Go to the [IntelliJ IDEA Download Page](https://www.jetbrains.com/idea/download/). The **Community Edition** is free and perfectly fine.
* **Install:** Run the installer with the default options.

---

## Running the Project

Once you have the prerequisites installed, follow these steps to get everything up and running.

### Step 1: Start the Databases
1. Open a terminal (or PowerShell) in the root directory of this project (`SII-SIA19`).
2. Run the following command to start all databases via Docker:
   ```bash
   docker compose up -d
   ```
   *(Note: This might take a few minutes the first time as it downloads the database images).*
3. You can verify they are running by opening the Docker Desktop app and looking at the Containers tab.

### Step 2: Open the Project in IntelliJ
1. Open IntelliJ IDEA.
2. Click on **Open** and select the root folder of this project (`SII-SIA19`).
3. Wait a moment for IntelliJ to index the files and recognize the Maven projects (you should see a little "M" icon on the `pom.xml` files).

### Step 3: Run the Microservices
The project consists of several microservices that need to be started in a specific order. You can either run them directly from IntelliJ (by finding the main class and clicking the green "Play" button) or by using the terminal.

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

### Step 4: Verify Everything is Working
Once all 5 services are running, you can test the system by opening your web browser and navigating to:
* `http://localhost:8095/realestate/v1/forsale/ppsf-by-state`
* `http://localhost:8095/realestate/v1/agents/top`

If you see data being returned, congratulations! The setup is complete and running successfully.

---
### Shutting Down
To stop everything, you can stop the running terminals (Ctrl+C). To stop the databases, run this command in the project root:
```bash
docker compose down
```
