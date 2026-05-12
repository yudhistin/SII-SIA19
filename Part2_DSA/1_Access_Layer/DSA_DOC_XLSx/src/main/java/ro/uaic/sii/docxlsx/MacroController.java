package ro.uaic.sii.docxlsx;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/macro")
@CrossOrigin(origins = "*")
public class MacroController {

    private final MacroService service;

    public MacroController(MacroService service) { this.service = service; }

    @GetMapping
    public List<MacroRecord> all() { return service.findAll(); }

    @GetMapping("/year/{year}")
    public List<MacroRecord> byYear(@PathVariable int year) { return service.findByYear(year); }
}
