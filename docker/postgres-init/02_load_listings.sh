#!/bin/bash
# Auto-runs on first boot of the postgres container.
# Loads listings_amsterdam.csv (produced by prepare_data.py) into a staging
# table, then projects it into the typed rentals.host / rentals.listing.

set -e

CSV=/data/listings_amsterdam.csv
if [ ! -f "$CSV" ]; then
    echo "[postgres-init] $CSV not found - skip seeding."
    echo "[postgres-init] Run 1_Data_Sources/prepare_data.py and re-create the volume."
    exit 0
fi

echo "[postgres-init] Loading $CSV ..."

psql -v ON_ERROR_STOP=1 --username "postgres" <<'EOSQL'
CREATE TABLE IF NOT EXISTS rentals.stg_listing (
    id TEXT, listing_url TEXT, scrape_id TEXT, last_scraped TEXT, source TEXT,
    name TEXT, description TEXT, neighborhood_overview TEXT, picture_url TEXT,
    host_id TEXT, host_url TEXT, host_name TEXT, host_since TEXT, host_location TEXT,
    host_about TEXT, host_response_time TEXT, host_response_rate TEXT,
    host_acceptance_rate TEXT, host_is_superhost TEXT, host_thumbnail_url TEXT,
    host_picture_url TEXT, host_neighbourhood TEXT, host_listings_count TEXT,
    host_total_listings_count TEXT, host_verifications TEXT, host_has_profile_pic TEXT,
    host_identity_verified TEXT, neighbourhood TEXT, neighbourhood_cleansed TEXT,
    neighbourhood_group_cleansed TEXT, latitude TEXT, longitude TEXT,
    property_type TEXT, room_type TEXT, accommodates TEXT, bathrooms TEXT,
    bathrooms_text TEXT, bedrooms TEXT, beds TEXT, amenities TEXT, price TEXT,
    minimum_nights TEXT, maximum_nights TEXT, minimum_minimum_nights TEXT,
    maximum_minimum_nights TEXT, minimum_maximum_nights TEXT,
    maximum_maximum_nights TEXT, minimum_nights_avg_ntm TEXT,
    maximum_nights_avg_ntm TEXT, calendar_updated TEXT, has_availability TEXT,
    availability_30 TEXT, availability_60 TEXT, availability_90 TEXT,
    availability_365 TEXT, calendar_last_scraped TEXT, number_of_reviews TEXT,
    number_of_reviews_ltm TEXT, number_of_reviews_l30d TEXT,
    availability_eoy TEXT, number_of_reviews_ly TEXT,
    estimated_occupancy_l365d TEXT, estimated_revenue_l365d TEXT,
    first_review TEXT, last_review TEXT,
    review_scores_rating TEXT, review_scores_accuracy TEXT,
    review_scores_cleanliness TEXT, review_scores_checkin TEXT,
    review_scores_communication TEXT, review_scores_location TEXT,
    review_scores_value TEXT, license TEXT, instant_bookable TEXT,
    calculated_host_listings_count TEXT,
    calculated_host_listings_count_entire_homes TEXT,
    calculated_host_listings_count_private_rooms TEXT,
    calculated_host_listings_count_shared_rooms TEXT,
    reviews_per_month TEXT
);
EOSQL

psql -v ON_ERROR_STOP=1 --username "postgres" \
    -c "\\COPY rentals.stg_listing FROM '$CSV' CSV HEADER DELIMITER ',' QUOTE '\"' ESCAPE '\"';"

psql -v ON_ERROR_STOP=1 --username "postgres" <<'EOSQL'
INSERT INTO rentals.host (host_id, host_name, host_since, host_location,
                          host_response_rate, host_acceptance_rate,
                          host_is_superhost, host_listings_count,
                          host_identity_verified)
SELECT DISTINCT
    NULLIF(host_id, '')::BIGINT,
    host_name,
    NULLIF(host_since, '')::DATE,
    host_location,
    host_response_rate,
    host_acceptance_rate,
    CASE host_is_superhost WHEN 't' THEN TRUE WHEN 'f' THEN FALSE END,
    NULLIF(host_listings_count, '')::INTEGER,
    CASE host_identity_verified WHEN 't' THEN TRUE WHEN 'f' THEN FALSE END
FROM rentals.stg_listing
WHERE host_id IS NOT NULL AND host_id <> ''
ON CONFLICT (host_id) DO NOTHING;

INSERT INTO rentals.listing (listing_id, host_id, listing_url, name, description,
                             neighbourhood, neighbourhood_cleansed, city,
                             latitude, longitude, property_type, room_type,
                             accommodates, bathrooms, bedrooms, beds, price,
                             minimum_nights, maximum_nights, availability_365,
                             number_of_reviews, review_scores_rating,
                             last_scraped, first_review, last_review)
SELECT
    NULLIF(id, '')::BIGINT,
    NULLIF(host_id, '')::BIGINT,
    listing_url, name, description,
    neighbourhood, neighbourhood_cleansed,
    'Amsterdam',
    NULLIF(latitude, '')::NUMERIC, NULLIF(longitude, '')::NUMERIC,
    property_type, room_type,
    NULLIF(accommodates, '')::INTEGER,
    NULLIF(bathrooms, '')::NUMERIC,
    NULLIF(bedrooms, '')::INTEGER,
    NULLIF(beds, '')::INTEGER,
    NULLIF(REPLACE(REPLACE(price, '$', ''), ',', ''), '')::NUMERIC,
    NULLIF(minimum_nights, '')::INTEGER,
    NULLIF(maximum_nights, '')::INTEGER,
    NULLIF(availability_365, '')::INTEGER,
    NULLIF(number_of_reviews, '')::INTEGER,
    NULLIF(review_scores_rating, '')::NUMERIC,
    NULLIF(last_scraped, '')::DATE,
    NULLIF(first_review, '')::DATE,
    NULLIF(last_review, '')::DATE
FROM rentals.stg_listing
ON CONFLICT (listing_id) DO NOTHING;

SELECT COUNT(*) AS hosts_loaded   FROM rentals.host;
SELECT COUNT(*) AS listings_loaded FROM rentals.listing;
EOSQL

echo "[postgres-init] Done."
