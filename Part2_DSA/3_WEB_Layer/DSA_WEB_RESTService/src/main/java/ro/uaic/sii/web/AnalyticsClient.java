package ro.uaic.sii.web;

import java.util.List;
import java.util.Map;

/** Driver-agnostic gateway to the SparkSQL analytical views. */
public interface AnalyticsClient {
    List<Map<String, Object>> query(String sql);
}
