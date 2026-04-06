// ============================================================
// DS5: Neo4j 5.13 -- Retail Location Graph
// SII-SIA19: Retail Sales Federated Analysis System
// Nodes: Country, Department, City
// Relationships: City-LOCATED_IN->Department, Department-PART_OF->Country
// ============================================================

// Clear existing data
MATCH (n) DETACH DELETE n;

// ── Countries ────────────────────────────────────────────────
CREATE (:Country {countryId: 1, countryName: 'United Kingdom',  countryCode: 'UK'});
CREATE (:Country {countryId: 2, countryName: 'France',          countryCode: 'FR'});
CREATE (:Country {countryId: 3, countryName: 'Germany',         countryCode: 'DE'});
CREATE (:Country {countryId: 4, countryName: 'Netherlands',     countryCode: 'NL'});
CREATE (:Country {countryId: 5, countryName: 'Spain',           countryCode: 'ES'});

// ── Departments ──────────────────────────────────────────────
CREATE (:Departament {departamentId: 1,  departamentName: 'Greater London',   countryCode: 'UK'});
CREATE (:Departament {departamentId: 2,  departamentName: 'West Midlands',    countryCode: 'UK'});
CREATE (:Departament {departamentId: 3,  departamentName: 'Ile-de-France',    countryCode: 'FR'});
CREATE (:Departament {departamentId: 4,  departamentName: 'Provence',         countryCode: 'FR'});
CREATE (:Departament {departamentId: 5,  departamentName: 'Bavaria',          countryCode: 'DE'});
CREATE (:Departament {departamentId: 6,  departamentName: 'North Rhine',      countryCode: 'DE'});
CREATE (:Departament {departamentId: 7,  departamentName: 'North Holland',    countryCode: 'NL'});
CREATE (:Departament {departamentId: 8,  departamentName: 'Catalonia',        countryCode: 'ES'});

// ── Cities ───────────────────────────────────────────────────
CREATE (:City {idCity: 1,  cityName: 'London',      postalCode: 'EC1A', departamentId: 1});
CREATE (:City {idCity: 2,  cityName: 'Birmingham',  postalCode: 'B1',   departamentId: 2});
CREATE (:City {idCity: 3,  cityName: 'Paris',        postalCode: '75001',departamentId: 3});
CREATE (:City {idCity: 4,  cityName: 'Marseille',   postalCode: '13001',departamentId: 4});
CREATE (:City {idCity: 5,  cityName: 'Munich',      postalCode: '80331',departamentId: 5});
CREATE (:City {idCity: 6,  cityName: 'Cologne',     postalCode: '50667',departamentId: 6});
CREATE (:City {idCity: 7,  cityName: 'Amsterdam',   postalCode: '1012', departamentId: 7});
CREATE (:City {idCity: 8,  cityName: 'Barcelona',   postalCode: '08001',departamentId: 8});

// ── Relationships ────────────────────────────────────────────
MATCH (c:City), (d:Departament) 
WHERE c.departamentId = d.departamentId
CREATE (c)-[:LOCATED_IN]->(d);

MATCH (d:Departament), (co:Country)
WHERE d.countryCode = co.countryCode
CREATE (d)-[:PART_OF]->(co);

// ── Verify ───────────────────────────────────────────────────
MATCH (c:City)-[:LOCATED_IN]->(d:Departament)-[:PART_OF]->(co:Country)
RETURN c.cityName, d.departamentName, co.countryName
ORDER BY co.countryName, d.departamentName;