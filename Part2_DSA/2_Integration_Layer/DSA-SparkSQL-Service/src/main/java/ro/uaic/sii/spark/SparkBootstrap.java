package ro.uaic.sii.spark;

import jakarta.annotation.PostConstruct;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Properties;

/**
 * On startup, registers temp views in Spark over the three Access-Layer sources:
 *   - csv_macro        from the FRED CSV (file path)
 *   - pg_host, pg_listing from Postgres rentals.* via JDBC
 *   - mongo_forsale    from MongoDB realestate.forsale via mongo-spark-connector
 * Then runs the 4 SparkSQL scripts to define analytical views.
 */
@Component
public class SparkBootstrap {

    private final SparkSession spark;

    @Value("${app.csv.macro-path}")  private String macroCsvPath;
    @Value("${app.postgres.url}")    private String pgUrl;
    @Value("${app.postgres.user}")   private String pgUser;
    @Value("${app.postgres.pass}")   private String pgPass;
    @Value("${app.mongo.uri}")       private String mongoUri;

    public SparkBootstrap(SparkSession spark) { this.spark = spark; }

    @PostConstruct
    public void registerViews() {
        // --- DS5: FRED macro CSV ---
        Dataset<Row> macro = spark.read()
                .option("header", "true").option("inferSchema", "true")
                .csv(macroCsvPath);
        macro.createOrReplaceTempView("csv_macro");

        // --- DS2: Postgres rentals ---
        Properties pg = new Properties();
        pg.setProperty("user", pgUser);
        pg.setProperty("password", pgPass);
        pg.setProperty("driver", "org.postgresql.Driver");

        spark.read().jdbc(pgUrl, "rentals.host", pg).createOrReplaceTempView("pg_host");
        spark.read().jdbc(pgUrl, "rentals.listing", pg).createOrReplaceTempView("pg_listing");

        // --- DS3: MongoDB for-sale ---
        Dataset<Row> mongo = spark.read()
                .format("mongodb")
                .option("connection.uri", mongoUri)
                .option("database", "realestate")
                .option("collection", "forsale")
                .load();
        mongo.createOrReplaceTempView("mongo_forsale");

        System.out.println("[SparkSQL] registered base views: csv_macro, pg_host, pg_listing, mongo_forsale");
        spark.sql("SHOW TABLES").show(false);
    }
}
