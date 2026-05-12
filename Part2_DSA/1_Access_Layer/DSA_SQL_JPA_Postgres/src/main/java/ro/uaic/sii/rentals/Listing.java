package ro.uaic.sii.rentals;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "listing", schema = "rentals")
public class Listing {
    @Id
    @Column(name = "listing_id")
    public Long listingId;

    @Column(name = "host_id")              public Long hostId;
    @Column(name = "name")                 public String name;
    @Column(name = "neighbourhood_cleansed") public String neighbourhood;
    @Column(name = "city")                 public String city;
    @Column(name = "latitude")             public BigDecimal latitude;
    @Column(name = "longitude")            public BigDecimal longitude;
    @Column(name = "property_type")        public String propertyType;
    @Column(name = "room_type")            public String roomType;
    @Column(name = "accommodates")         public Integer accommodates;
    @Column(name = "bedrooms")             public Integer bedrooms;
    @Column(name = "beds")                 public Integer beds;
    @Column(name = "price")                public BigDecimal price;
    @Column(name = "minimum_nights")       public Integer minimumNights;
    @Column(name = "availability_365")     public Integer availability365;
    @Column(name = "number_of_reviews")    public Integer numberOfReviews;
    @Column(name = "review_scores_rating") public BigDecimal reviewScoresRating;
    @Column(name = "last_scraped")         public LocalDate lastScraped;
}
