package ro.uaic.sii.rentals;

// Top-level repository interfaces (one per file is preferred but Java permits
// multiple top-level types in one file when only one is public).

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface Repositories {
    // Marker - keeps file public; the actual repos are below.
}

interface HostRepo extends JpaRepository<Host, Long> {}

interface ListingRepo extends JpaRepository<Listing, Long> {
    List<Listing> findByNeighbourhood(String neighbourhood);
    List<Listing> findByRoomType(String roomType);

    @Query("SELECT l FROM Listing l WHERE l.price BETWEEN :min AND :max")
    List<Listing> findByPriceRange(double min, double max);
}
