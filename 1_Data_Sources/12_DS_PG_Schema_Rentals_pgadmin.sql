-- ============================================================
-- DS2: PostgreSQL 14 - Airbnb Rentals + Hosts (pgAdmin version)
-- Run as postgres user in pgAdmin Query Tool (F5).
-- Uses server-side COPY (file is already inside the container at /tmp/).
-- ============================================================

-- Pas 2: Schema and tables
CREATE SCHEMA IF NOT EXISTS rentals;

CREATE TABLE IF NOT EXISTS rentals.host (
    host_id                 BIGINT PRIMARY KEY,
    host_name               VARCHAR(150),
    host_since              DATE,
    host_location           VARCHAR(200),
    host_response_rate      VARCHAR(10),
    host_acceptance_rate    VARCHAR(10),
    host_is_superhost       BOOLEAN,
    host_listings_count     INTEGER,
    host_identity_verified  BOOLEAN
);

CREATE TABLE IF NOT EXISTS rentals.listing (
    listing_id              BIGINT PRIMARY KEY,
    host_id                 BIGINT REFERENCES rentals.host(host_id),
    listing_url             VARCHAR(300),
    name                    VARCHAR(300),
    description             TEXT,
    neighbourhood           VARCHAR(150),
    neighbourhood_cleansed  VARCHAR(150),
    city                    VARCHAR(80),
    latitude                NUMERIC(10,6),
    longitude               NUMERIC(10,6),
    property_type           VARCHAR(80),
    room_type               VARCHAR(40),
    accommodates            INTEGER,
    bathrooms               NUMERIC(4,1),
    bedrooms                INTEGER,
    beds                    INTEGER,
    price                   NUMERIC(10,2),
    minimum_nights          INTEGER,
    maximum_nights          INTEGER,
    availability_365        INTEGER,
    number_of_reviews       INTEGER,
    review_scores_rating    NUMERIC(4,2),
    last_scraped            DATE,
    first_review            DATE,
    last_review             DATE
);

CREATE INDEX IF NOT EXISTS idx_listing_neighbourhood ON rentals.listing(neighbourhood_cleansed);
CREATE INDEX IF NOT EXISTS idx_listing_room_type     ON rentals.listing(room_type);
CREATE INDEX IF NOT EXISTS idx_host_superhost        ON rentals.host(host_is_superhost);

-- Pas 3: Staging table (all 79 Airbnb columns as TEXT)
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
    first_review TEXT, last_review TEXT, review_scores_rating TEXT,
    review_scores_accuracy TEXT, review_scores_cleanliness TEXT,
    review_scores_checkin TEXT, review_scores_communication TEXT,
    review_scores_location TEXT, review_scores_value TEXT, license TEXT,
    instant_bookable TEXT, calculated_host_listings_count TEXT,
    calculated_host_listings_count_entire_homes TEXT,
    calculated_host_listings_count_private_rooms TEXT,
    calculated_host_listings_count_shared_rooms TEXT,
    reviews_per_month TEXT
);

-- Pas 4: Load CSV — server-side COPY reads from inside the container
COPY rentals.stg_listing
FROM '/tmp/listings_amsterdam.csv'
CSV HEADER DELIMITER ',' QUOTE '"' ESCAPE '"';

-- Pas 5: Project staging into typed tables
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
    NULLIF(latitude,  '')::NUMERIC,
    NULLIF(longitude, '')::NUMERIC,
    property_type, room_type,
    NULLIF(accommodates, '')::INTEGER,
    NULLIF(bathrooms,    '')::NUMERIC,
    NULLIF(bedrooms,     '')::INTEGER,
    NULLIF(beds,         '')::INTEGER,
    NULLIF(REPLACE(REPLACE(price, '$', ''), ',', ''), '')::NUMERIC,
    NULLIF(minimum_nights,    '')::INTEGER,
    NULLIF(maximum_nights,    '')::INTEGER,
    NULLIF(availability_365,  '')::INTEGER,
    NULLIF(number_of_reviews, '')::INTEGER,
    NULLIF(review_scores_rating, '')::NUMERIC,
    NULLIF(last_scraped,  '')::DATE,
    NULLIF(first_review,  '')::DATE,
    NULLIF(last_review,   '')::DATE
FROM rentals.stg_listing
ON CONFLICT (listing_id) DO NOTHING;

-- Pas 6: PostgREST role
CREATE ROLE web_anon NOLOGIN;
GRANT USAGE ON SCHEMA rentals TO web_anon;
GRANT SELECT ON rentals.host, rentals.listing TO web_anon;

-- Pas 7: Verification
SELECT 'hosts'    AS tbl, COUNT(*) FROM rentals.host
UNION ALL
SELECT 'listings', COUNT(*) FROM rentals.listing;

SELECT neighbourhood_cleansed, room_type, COUNT(*) nr,
       ROUND(AVG(price)::numeric, 2) avg_price
FROM rentals.listing
GROUP BY neighbourhood_cleansed, room_type
ORDER BY nr DESC
LIMIT 15;
