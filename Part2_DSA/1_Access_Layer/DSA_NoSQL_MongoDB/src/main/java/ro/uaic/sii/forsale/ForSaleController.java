package ro.uaic.sii.forsale;

import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/forsale")
@CrossOrigin(origins = "*")
public class ForSaleController {

    private final ForSaleRepo repo;

    public ForSaleController(ForSaleRepo repo) { this.repo = repo; }

    @GetMapping
    public List<ForSaleListing> all(@RequestParam(defaultValue = "0")   int page,
                                    @RequestParam(defaultValue = "500") int size) {
        return repo.findAll(PageRequest.of(page, size)).getContent();
    }

    @GetMapping("/state/{state}")
    public List<ForSaleListing> byState(@PathVariable String state) {
        return repo.findByState(state);
    }

    @GetMapping("/state/{state}/city/{city}")
    public List<ForSaleListing> byStateCity(@PathVariable String state, @PathVariable String city) {
        return repo.findByStateAndCity(state, city);
    }

    @GetMapping("/top500")
    public List<ForSaleListing> top500() {
        return repo.findTop500ByStatusOrderByPriceDesc("for_sale");
    }
}
