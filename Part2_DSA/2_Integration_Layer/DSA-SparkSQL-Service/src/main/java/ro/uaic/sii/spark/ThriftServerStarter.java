package ro.uaic.sii.spark;

import jakarta.annotation.PostConstruct;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.hive.thriftserver.HiveThriftServer2;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.DependsOn;
import org.springframework.stereotype.Component;

/**
 * Starts the embedded Hive Thrift Server so that DBeaver / DataGrip and the
 * DSA_WEB_RESTService can query the SparkSQL temp views via Hive JDBC at
 * jdbc:hive2://localhost:10000
 *
 * Disabled by default via spark.thrift.enabled=false in application.yml; flip
 * it on once the Spark warehouse + Hive metastore env is configured.
 */
@Component
@DependsOn("sparkBootstrap")
@ConditionalOnProperty(name = "spark.thrift.enabled", havingValue = "true")
public class ThriftServerStarter {

    private final SparkSession spark;

    @Value("${spark.thrift.port}") private int port;

    public ThriftServerStarter(SparkSession spark) { this.spark = spark; }

    @PostConstruct
    public void start() {
        spark.sparkContext().conf().set("hive.server2.thrift.port", String.valueOf(port));
        HiveThriftServer2.startWithContext(spark.sqlContext());
        System.out.println("[Thrift] Hive Thrift Server listening on jdbc:hive2://localhost:" + port);
    }
}
