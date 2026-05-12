package ro.uaic.sii.spark;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/sql")
@CrossOrigin(origins = "*")
public class SqlController {

    private final SparkSession spark;

    public SqlController(SparkSession spark) { this.spark = spark; }

    @GetMapping
    public List<Map<String, Object>> get(@RequestParam("q") String query,
                                         @RequestParam(defaultValue = "1000") int limit) {
        return run(query, limit);
    }

    @PostMapping
    public List<Map<String, Object>> post(@RequestBody Map<String, String> body,
                                          @RequestParam(defaultValue = "1000") int limit) {
        return run(body.get("q"), limit);
    }

    @GetMapping("/tables")
    public List<Map<String, Object>> tables() {
        return rowsToMaps(spark.sql("SHOW TABLES").collectAsList());
    }

    @GetMapping("/describe")
    public List<Map<String, Object>> describe(@RequestParam String table) {
        return rowsToMaps(spark.sql("DESCRIBE " + table).collectAsList());
    }

    private List<Map<String, Object>> run(String query, int limit) {
        Dataset<Row> df = spark.sql(query);
        if (limit > 0) df = df.limit(limit);
        return rowsToMaps(df.collectAsList());
    }

    private static List<Map<String, Object>> rowsToMaps(List<Row> rows) {
        List<Map<String, Object>> out = new ArrayList<>(rows.size());
        for (Row r : rows) {
            Map<String, Object> m = new LinkedHashMap<>();
            String[] names = r.schema().fieldNames();
            for (int i = 0; i < names.length; i++) m.put(names[i], r.get(i));
            out.add(m);
        }
        return out;
    }
}
