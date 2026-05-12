package ro.uaic.sii.web;

import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Final REST layer. Same endpoint shape as ORDS in Part 1, but backed by
 * Spark SQL through Hive JDBC (or HTTP fallback). The dashboard's index.html
 * can swap its base URL to point here for zero-downtime cutover.
 */
@RestController
@RequestMapping("/realestate/v1")
@CrossOrigin(origins = "*")
public class AnalyticsController {

    private final AnalyticsClient client;

    public AnalyticsController(AnalyticsClient client) { this.client = client; }

    @GetMapping("/sales/cube")
    public List<Map<String, Object>> salesCube() {
        return client.query("SELECT * FROM a_sales_geo_time_cube ORDER BY city_name, sale_year, sale_quarter");
    }

    @GetMapping("/sales/vs-mortgage")
    public List<Map<String, Object>> salesVsMortgage() {
        return client.query("SELECT * FROM a_sales_vs_mortgage ORDER BY year_month");
    }

    @GetMapping("/forsale/ppsf-by-state")
    public List<Map<String, Object>> ppsfByState() {
        return client.query("SELECT * FROM a_forsale_ppsf_by_state");
    }

    @GetMapping("/rentals/yield")
    public List<Map<String, Object>> rentalYield() {
        return client.query("SELECT * FROM a_rental_vs_sale");
    }

    @GetMapping("/agents/top")
    public List<Map<String, Object>> topAgents() {
        return client.query("SELECT * FROM a_top_agents");
    }

    @GetMapping("/geo/coverage")
    public List<Map<String, Object>> geoCoverage() {
        return client.query("SELECT * FROM a_geo_coverage");
    }

    @PostMapping("/sql")
    public List<Map<String, Object>> ad_hoc(@RequestBody Map<String, String> body) {
        return client.query(body.get("q"));
    }
}
