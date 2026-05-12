package ro.uaic.sii.rentals;

import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class RentalsController {

    private final ListingRepo listings;
    private final HostRepo    hosts;

    public RentalsController(ListingRepo l, HostRepo h) {
        this.listings = l;
        this.hosts = h;
    }

    @GetMapping("/listings")
    public List<Listing> listings(@RequestParam(defaultValue = "0")   int page,
                                  @RequestParam(defaultValue = "200") int size) {
        return listings.findAll(PageRequest.of(page, size)).getContent();
    }

    @GetMapping("/listings/by-neighbourhood/{n}")
    public List<Listing> byNeighbourhood(@PathVariable String n) {
        return listings.findByNeighbourhood(n);
    }

    @GetMapping("/listings/by-room-type/{t}")
    public List<Listing> byRoomType(@PathVariable String t) {
        return listings.findByRoomType(t);
    }

    @GetMapping("/hosts")
    public List<Host> hosts(@RequestParam(defaultValue = "0")   int page,
                            @RequestParam(defaultValue = "200") int size) {
        return hosts.findAll(PageRequest.of(page, size)).getContent();
    }

    @GetMapping("/hosts/{id}")
    public Host host(@PathVariable Long id) { return hosts.findById(id).orElseThrow(); }
}
