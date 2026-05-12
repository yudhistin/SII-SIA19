package ro.uaic.sii.forsale;

import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ForSaleRepo extends MongoRepository<ForSaleListing, String> {
    List<ForSaleListing> findByState(String state);
    List<ForSaleListing> findByStateAndCity(String state, String city);
    List<ForSaleListing> findTop500ByStatusOrderByPriceDesc(String status);
}
