package ro.uaic.sii.rentals;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "host", schema = "rentals")
public class Host {
    @Id
    @Column(name = "host_id")
    public Long hostId;

    @Column(name = "host_name")        public String hostName;
    @Column(name = "host_since")       public LocalDate hostSince;
    @Column(name = "host_location")    public String hostLocation;
    @Column(name = "host_response_rate")   public String hostResponseRate;
    @Column(name = "host_acceptance_rate") public String hostAcceptanceRate;
    @Column(name = "host_is_superhost")    public Boolean hostIsSuperhost;
    @Column(name = "host_listings_count")  public Integer hostListingsCount;
    @Column(name = "host_identity_verified") public Boolean hostIdentityVerified;
}
