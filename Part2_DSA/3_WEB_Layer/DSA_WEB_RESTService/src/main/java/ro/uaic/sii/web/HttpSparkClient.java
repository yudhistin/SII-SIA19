package ro.uaic.sii.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/** Fallback driver: hits the SparkSQL service's /sql endpoint via HTTP. */
@Service
@ConditionalOnProperty(name = "app.driver", havingValue = "http")
public class HttpSparkClient implements AnalyticsClient {

    @Value("${app.spark.http-url}") private String baseUrl;

    @Override
    public List<Map<String, Object>> query(String sql) {
        String url = baseUrl + "/sql?q=" + URLEncoder.encode(sql, StandardCharsets.UTF_8);
        // Pass URI directly — WebClient.uri(String) re-encodes the already-encoded query.
        return WebClient.create()
                .get().uri(java.net.URI.create(url))
                .retrieve()
                .bodyToMono(new ParameterizedTypeReference<List<Map<String, Object>>>() {})
                .block();
    }
}
