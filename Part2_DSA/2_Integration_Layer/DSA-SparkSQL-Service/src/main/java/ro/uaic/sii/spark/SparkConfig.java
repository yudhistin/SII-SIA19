package ro.uaic.sii.spark;

import org.apache.spark.SparkConf;
import org.apache.spark.sql.SparkSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SparkConfig {

    @Value("${spark.app-name}")    private String appName;
    @Value("${spark.master}")      private String master;
    @Value("${spark.warehouse-dir}") private String warehouse;

    @Bean
    public SparkSession sparkSession() {
        SparkConf conf = new SparkConf()
                .setAppName(appName)
                .setMaster(master)
                .set("spark.sql.warehouse.dir", warehouse)
                .set("spark.sql.catalogImplementation", "in-memory")
                .set("spark.driver.host", "127.0.0.1")
                .set("spark.ui.enabled", "false")
                .set("spark.sql.legacy.timeParserPolicy", "LEGACY");

        return SparkSession.builder().config(conf).getOrCreate();
    }
}
