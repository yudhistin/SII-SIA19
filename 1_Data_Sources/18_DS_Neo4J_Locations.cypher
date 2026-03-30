// DS: Neo4j Locations Graph
// SIA19 - Data Source Lab 3

CREATE 
(c1:City {idCity: 1, cityName: 'Bucuresti', postalCode: '010011'}) -[:LOCATED_IN]-> (d1:Departament {idDepartament: 1, departamentName: 'Muntenia', countryName: 'Romania'}),
(c2:City {idCity: 2, cityName: 'Iasi', postalCode: '700001'}) -[:LOCATED_IN]-> (d2:Departament {idDepartament: 2, departamentName: 'Moldova', countryName: 'Romania'}),
(c3:City {idCity: 3, cityName: 'Cluj-Napoca', postalCode: '400001'}) -[:LOCATED_IN]-> (d3:Departament {idDepartament: 3, departamentName: 'Transilvania', countryName: 'Romania'}),
(c4:City {idCity: 4, cityName: 'Timisoara', postalCode: '300001'}) -[:LOCATED_IN]-> (d3),
(c5:City {idCity: 5, cityName: 'Craiova', postalCode: '200001'}) -[:LOCATED_IN]-> (d4:Departament {idDepartament: 4, departamentName: 'Oltenia', countryName: 'Romania'}),
(c6:City {idCity: 6, cityName: 'Brasov', postalCode: '500001'}) -[:LOCATED_IN]-> (d3),
(c7:City {idCity: 7, cityName: 'Constanta', postalCode: '900001'}) -[:LOCATED_IN]-> (d1),
(c8:City {idCity: 8, cityName: 'Galati', postalCode: '800001'}) -[:LOCATED_IN]-> (d2)