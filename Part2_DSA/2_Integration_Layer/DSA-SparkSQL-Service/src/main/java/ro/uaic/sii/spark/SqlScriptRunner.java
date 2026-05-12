package ro.uaic.sii.spark;

import jakarta.annotation.PostConstruct;
import org.apache.spark.sql.SparkSession;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.DependsOn;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.file.*;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

/** Runs the .sql scripts in 2_Integration_Layer/sql/ in order, after base views are registered. */
@Component
@DependsOn("sparkBootstrap")
public class SqlScriptRunner {

    private final SparkSession spark;

    @Value("${app.sql.scripts-dir}") private String scriptsDir;

    public SqlScriptRunner(SparkSession spark) { this.spark = spark; }

    @PostConstruct
    public void runScripts() throws IOException {
        Path dir = Paths.get(scriptsDir).toAbsolutePath().normalize();
        if (!Files.isDirectory(dir)) {
            System.err.println("[SqlScriptRunner] scripts dir not found: " + dir);
            return;
        }

        List<Path> files;
        try (var s = Files.list(dir)) {
            files = s.filter(p -> p.toString().toLowerCase().endsWith(".sql"))
                     .sorted(Comparator.comparing(p -> p.getFileName().toString()))
                     .toList();
        }

        for (Path f : files) {
            System.out.println("[SqlScriptRunner] running " + f.getFileName());
            String content = Files.readString(f);
            for (String stmt : splitStatements(content)) {
                if (stmt.isBlank()) continue;
                try {
                    spark.sql(stmt);
                } catch (Exception e) {
                    System.err.println("  ! failed: " + e.getMessage());
                    System.err.println("    stmt: " + stmt.lines().limit(2).reduce("", (a, b) -> a + b + " | "));
                }
            }
        }
        System.out.println("[SqlScriptRunner] all done. Current tables/views:");
        spark.sql("SHOW TABLES").show(false);
    }

    /** Naive split on ';' at end of line; ignores -- line comments. */
    private static String[] splitStatements(String script) {
        // strip line comments
        String cleaned = Arrays.stream(script.split("\\R"))
                .map(l -> {
                    int idx = l.indexOf("--");
                    return idx >= 0 ? l.substring(0, idx) : l;
                })
                .reduce("", (a, b) -> a + "\n" + b);
        return cleaned.split(";");
    }
}
