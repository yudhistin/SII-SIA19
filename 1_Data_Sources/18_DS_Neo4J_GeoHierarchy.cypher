// ============================================================
// DS4: Neo4j 5.x - Real Estate Geographic Hierarchy
// SII-SIA19: Integrated Real Estate Market Analysis System
//
// Role  : Conformed GEO dimension shared by all data sources.
//         Country -> Region/State -> City -> Neighborhood.
// Scope : Covers every geography that appears in DS1 (NYC sales),
//         DS2 (Amsterdam rentals), DS3 (Realtor.com listings).
// ============================================================

// Reset (idempotent reload)
MATCH (n) DETACH DELETE n;

// Constraints
CREATE CONSTRAINT country_code  IF NOT EXISTS FOR (c:Country)      REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT region_id     IF NOT EXISTS FOR (r:Region)       REQUIRE r.code IS UNIQUE;
CREATE CONSTRAINT city_id       IF NOT EXISTS FOR (c:City)         REQUIRE c.id   IS UNIQUE;
CREATE CONSTRAINT nhood_id      IF NOT EXISTS FOR (n:Neighborhood) REQUIRE n.id   IS UNIQUE;

// ---------- COUNTRIES ----------
CREATE (us:Country {code: 'US', name: 'United States'});
CREATE (nl:Country {code: 'NL', name: 'Netherlands'});

// ---------- US REGIONS (states relevant to DS1 + DS3) ----------
MATCH (us:Country {code: 'US'})
CREATE
  (us)<-[:PART_OF]-(:Region {code: 'US-NY', name: 'New York',     type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-CA', name: 'California',   type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-TX', name: 'Texas',        type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-FL', name: 'Florida',      type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-MA', name: 'Massachusetts',type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-IL', name: 'Illinois',     type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-WA', name: 'Washington',   type: 'State'}),
  (us)<-[:PART_OF]-(:Region {code: 'US-CO', name: 'Colorado',     type: 'State'});

// ---------- NL REGIONS (provinces relevant to DS2) ----------
MATCH (nl:Country {code: 'NL'})
CREATE
  (nl)<-[:PART_OF]-(:Region {code: 'NL-NH', name: 'Noord-Holland', type: 'Province'}),
  (nl)<-[:PART_OF]-(:Region {code: 'NL-ZH', name: 'Zuid-Holland',  type: 'Province'}),
  (nl)<-[:PART_OF]-(:Region {code: 'NL-UT', name: 'Utrecht',       type: 'Province'});

// ---------- US CITIES (NYC boroughs treated as City-level for DS1) ----------
MATCH (ny:Region {code: 'US-NY'})
CREATE
  (ny)<-[:PART_OF]-(:City {id: 'US-NY-MAN', name: 'Manhattan',     postalCode: '10001'}),
  (ny)<-[:PART_OF]-(:City {id: 'US-NY-BRK', name: 'Brooklyn',      postalCode: '11201'}),
  (ny)<-[:PART_OF]-(:City {id: 'US-NY-QNS', name: 'Queens',        postalCode: '11101'}),
  (ny)<-[:PART_OF]-(:City {id: 'US-NY-BRX', name: 'Bronx',         postalCode: '10451'}),
  (ny)<-[:PART_OF]-(:City {id: 'US-NY-STN', name: 'Staten Island', postalCode: '10301'});

MATCH (ca:Region {code: 'US-CA'})
CREATE
  (ca)<-[:PART_OF]-(:City {id: 'US-CA-LAX', name: 'Los Angeles',   postalCode: '90001'}),
  (ca)<-[:PART_OF]-(:City {id: 'US-CA-SFO', name: 'San Francisco', postalCode: '94102'}),
  (ca)<-[:PART_OF]-(:City {id: 'US-CA-SDG', name: 'San Diego',     postalCode: '92101'});

MATCH (tx:Region {code: 'US-TX'})
CREATE
  (tx)<-[:PART_OF]-(:City {id: 'US-TX-HOU', name: 'Houston', postalCode: '77001'}),
  (tx)<-[:PART_OF]-(:City {id: 'US-TX-AUS', name: 'Austin',  postalCode: '73301'}),
  (tx)<-[:PART_OF]-(:City {id: 'US-TX-DAL', name: 'Dallas',  postalCode: '75201'});

MATCH (fl:Region {code: 'US-FL'})
CREATE
  (fl)<-[:PART_OF]-(:City {id: 'US-FL-MIA', name: 'Miami',   postalCode: '33101'}),
  (fl)<-[:PART_OF]-(:City {id: 'US-FL-ORL', name: 'Orlando', postalCode: '32801'});

MATCH (ma:Region {code: 'US-MA'})
CREATE (ma)<-[:PART_OF]-(:City {id: 'US-MA-BOS', name: 'Boston',  postalCode: '02101'});

MATCH (il:Region {code: 'US-IL'})
CREATE (il)<-[:PART_OF]-(:City {id: 'US-IL-CHI', name: 'Chicago', postalCode: '60601'});

MATCH (wa:Region {code: 'US-WA'})
CREATE (wa)<-[:PART_OF]-(:City {id: 'US-WA-SEA', name: 'Seattle', postalCode: '98101'});

MATCH (co:Region {code: 'US-CO'})
CREATE (co)<-[:PART_OF]-(:City {id: 'US-CO-DEN', name: 'Denver',  postalCode: '80202'});

// ---------- NL CITIES (DS2 = Amsterdam) ----------
MATCH (nh:Region {code: 'NL-NH'})
CREATE
  (nh)<-[:PART_OF]-(:City {id: 'NL-NH-AMS', name: 'Amsterdam', postalCode: '1011'}),
  (nh)<-[:PART_OF]-(:City {id: 'NL-NH-HRL', name: 'Haarlem',   postalCode: '2011'});

MATCH (zh:Region {code: 'NL-ZH'})
CREATE (zh)<-[:PART_OF]-(:City {id: 'NL-ZH-RTM', name: 'Rotterdam', postalCode: '3011'});

MATCH (ut:Region {code: 'NL-UT'})
CREATE (ut)<-[:PART_OF]-(:City {id: 'NL-UT-UTR', name: 'Utrecht',   postalCode: '3511'});

// ---------- NEIGHBORHOODS (sample, focused on DS1 + DS2 hot zones) ----------
// Manhattan neighborhoods (match NYC Rolling Sales NEIGHBORHOOD column)
MATCH (man:City {id: 'US-NY-MAN'})
CREATE
  (man)<-[:PART_OF]-(:Neighborhood {id: 'NYC-MAN-UES', name: 'UPPER EAST SIDE'}),
  (man)<-[:PART_OF]-(:Neighborhood {id: 'NYC-MAN-UWS', name: 'UPPER WEST SIDE'}),
  (man)<-[:PART_OF]-(:Neighborhood {id: 'NYC-MAN-MID', name: 'MIDTOWN WEST'}),
  (man)<-[:PART_OF]-(:Neighborhood {id: 'NYC-MAN-FID', name: 'FINANCIAL'}),
  (man)<-[:PART_OF]-(:Neighborhood {id: 'NYC-MAN-HAR', name: 'HARLEM-CENTRAL'});

MATCH (brk:City {id: 'US-NY-BRK'})
CREATE
  (brk)<-[:PART_OF]-(:Neighborhood {id: 'NYC-BRK-WLB', name: 'WILLIAMSBURG-NORTH'}),
  (brk)<-[:PART_OF]-(:Neighborhood {id: 'NYC-BRK-DUM', name: 'DOWNTOWN-FULTON FERRY'}),
  (brk)<-[:PART_OF]-(:Neighborhood {id: 'NYC-BRK-PSL', name: 'PARK SLOPE'});

// Amsterdam neighborhoods (match Inside Airbnb neighbourhood_cleansed)
MATCH (ams:City {id: 'NL-NH-AMS'})
CREATE
  (ams)<-[:PART_OF]-(:Neighborhood {id: 'AMS-CW',  name: 'Centrum-West'}),
  (ams)<-[:PART_OF]-(:Neighborhood {id: 'AMS-CO',  name: 'Centrum-Oost'}),
  (ams)<-[:PART_OF]-(:Neighborhood {id: 'AMS-DPS', name: 'De Pijp - Rivierenbuurt'}),
  (ams)<-[:PART_OF]-(:Neighborhood {id: 'AMS-OOM', name: 'Oud-Oost'}),
  (ams)<-[:PART_OF]-(:Neighborhood {id: 'AMS-WEW', name: 'Westerpark'});

// ---------- VERIFICATION ----------
// Counts per label
MATCH (n)
RETURN labels(n)[0] AS label, COUNT(*) AS nr
ORDER BY nr DESC;

// Path: NL -> Amsterdam -> De Pijp
MATCH p = (c:Country {code:'NL'})<-[:PART_OF*]-(n:Neighborhood {name:'De Pijp - Rivierenbuurt'})
RETURN p;

// All cities in New York state
MATCH (c:City)-[:PART_OF]->(:Region {code:'US-NY'})
RETURN c.id, c.name, c.postalCode
ORDER BY c.name;

// Full hierarchy export (used by Spark SQL geo dimension view)
MATCH (nh:Neighborhood)-[:PART_OF]->(ci:City)-[:PART_OF]->(rg:Region)-[:PART_OF]->(co:Country)
RETURN co.code AS country_code, co.name AS country,
       rg.code AS region_code,  rg.name AS region,
       ci.id   AS city_id,      ci.name AS city,
       nh.id   AS neighborhood_id, nh.name AS neighborhood
ORDER BY country, region, city, neighborhood;
