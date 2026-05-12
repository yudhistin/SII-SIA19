package ro.uaic.sii.docxlsx;

import com.opencsv.CSVReader;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.FileReader;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class MacroService {

    @Value("${app.macro.csv-path}")
    private String csvPath;

    private final List<MacroRecord> cache = new ArrayList<>();

    @PostConstruct
    public void load() {
        cache.clear();
        try (CSVReader r = new CSVReader(new FileReader(csvPath))) {
            String[] row;
            int i = 0;
            while ((row = r.readNext()) != null) {
                if (i++ == 0) continue;  // skip header
                cache.add(new MacroRecord(
                        LocalDate.parse(row[0]),
                        parseD(row, 1),
                        parseD(row, 2),
                        parseD(row, 3),
                        parseD(row, 4),
                        parseI(row, 5)
                ));
            }
            System.out.println("[DSA_DOC_XLSx] loaded " + cache.size() + " macro rows from " + csvPath);
        } catch (Exception e) {
            throw new RuntimeException("Failed to load macro CSV: " + csvPath, e);
        }
    }

    public List<MacroRecord> findAll() { return List.copyOf(cache); }

    public List<MacroRecord> findByYear(int year) {
        return cache.stream()
                .filter(m -> m.periodDate().getYear() == year)
                .toList();
    }

    private static Double parseD(String[] row, int idx) {
        if (idx >= row.length || row[idx] == null || row[idx].isBlank()) return null;
        try { return Double.parseDouble(row[idx].trim()); } catch (Exception e) { return null; }
    }
    private static Integer parseI(String[] row, int idx) {
        if (idx >= row.length || row[idx] == null || row[idx].isBlank()) return null;
        try { return Integer.parseInt(row[idx].trim()); } catch (Exception e) { return null; }
    }
}
