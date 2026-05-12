package ro.uaic.sii.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.*;

/**
 * Uses the Hive JDBC driver to talk to Spark's Thrift Server (port 10000).
 * Activated when app.driver=hive (the default). Switch to app.driver=http to
 * fall back to HTTP calls against the SparkSQL service's /sql endpoint.
 */
@Service
@ConditionalOnProperty(name = "app.driver", havingValue = "hive", matchIfMissing = true)
public class HiveJdbcClient implements AnalyticsClient {

    @Value("${app.hive.url}")  private String url;
    @Value("${app.hive.user}") private String user;
    @Value("${app.hive.pass}") private String pass;

    @Override
    public List<Map<String, Object>> query(String sql) {
        try (Connection c = DriverManager.getConnection(url, user, pass);
             Statement  s = c.createStatement();
             ResultSet  rs = s.executeQuery(sql)) {

            ResultSetMetaData md = rs.getMetaData();
            int cols = md.getColumnCount();
            List<Map<String, Object>> out = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= cols; i++) row.put(md.getColumnLabel(i), rs.getObject(i));
                out.add(row);
            }
            return out;
        } catch (SQLException e) {
            throw new RuntimeException("Hive JDBC query failed: " + e.getMessage(), e);
        }
    }
}
