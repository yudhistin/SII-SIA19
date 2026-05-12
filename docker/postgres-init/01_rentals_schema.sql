-- Auto-runs on first boot of the postgres container.
-- Creates the rentals schema, the staging table, and the PostgREST anon role.
-- The actual CSV import is done by 02_load_listings.sh next to this file.

CREATE SCHEMA IF NOT EXISTS rentals;

CREATE TABLE IF NOT EXISTS rentals.host (
    host_id              BIGINT PRIMARY KEY,
    host_name            VARCHAR(150),
    host_since           DATE,
    host_location        VARCHAR(200),
    host_response_rate   VARCHAR(10),
    host_acceptance_rate VARCHAR(10),
    host_is_superhost    BOOLEAN,
    host_listings_count  INTEGER,
    host_identity_verified BOOLEAN
);

CREATE TABLE IF NOT EXISTS rentals.listing (
    listing_id           BIGINT PRIMARY KEY,
    host_id              BIGINT REFERENCES rentals.host(host_id),
    listing_url          VARCHAR(300),
    name                 VARCHAR(300),
    description          TEXT,
    neighbourhood        VARCHAR(150),
    neighbourhood_cleansed VARCHAR(150),
    city                 VARCHAR(80),
    latitude             NUMERIC(10,6),
    longitude            NUMERIC(10,6),
    property_type        VARCHAR(80),
    room_type            VARCHAR(40),
    accommodates         INTEGER,
    bathrooms            NUMERIC(4,1),
    bedrooms             INTEGER,
    beds                 INTEGER,
    price                NUMERIC(10,2),
    minimum_nights       INTEGER,
    maximum_nights       INTEGER,
    availability_365     INTEGER,
    number_of_reviews    INTEGER,
    review_scores_rating NUMERIC(4,2),
    last_scraped         DATE,
    first_review         DATE,
    last_review          DATE
);

CREATE INDEX IF NOT EXISTS idx_listing_neighbourhood ON rentals.listing(neighbourhood_cleansed);
CREATE INDEX IF NOT EXISTS idx_listing_room_type    ON rentals.listing(room_type);
CREATE INDEX IF NOT EXISTS idx_host_superhost       ON rentals.host(host_is_superhost);

-- PostgREST anonymous role
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'web_anon') THEN
        CREATE ROLE web_anon NOLOGIN;
    END IF;
END $$;
GRANT USAGE ON SCHEMA rentals TO web_anon;
GRANT SELECT ON rentals.host, rentals.listing TO web_anon;
