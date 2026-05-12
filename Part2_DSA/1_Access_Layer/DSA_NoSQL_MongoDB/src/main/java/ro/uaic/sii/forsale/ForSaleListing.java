package ro.uaic.sii.forsale;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document(collection = "forsale")
public class ForSaleListing {

    @Id
    public String id;

    @Field("brokered_by")    public Double brokeredBy;
    @Field("status")         public String status;
    @Field("price")          public Double price;
    @Field("bed")            public Integer bed;
    @Field("bath")           public Integer bath;
    @Field("acre_lot")       public Double acreLot;
    @Field("street")         public Double street;
    @Field("city")           public String city;
    @Field("state")          public String state;
    @Field("zip_code")       public String zipCode;
    @Field("house_size")     public Double houseSize;
    @Field("prev_sold_date") public String prevSoldDate;
}
