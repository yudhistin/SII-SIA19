// DS: MongoDB Locations Collection
// SIA19 - Data Source Lab 3

use('mds');

db.Locations.insertMany([
    { location_id: 1, city_name: "Bucuresti", postal_code: "010011", department_id: 1, country: "Romania", lat: 44.4268, lng: 26.1025 },
    { location_id: 2, city_name: "Iasi", postal_code: "700001", department_id: 2, country: "Romania", lat: 47.1585, lng: 27.6014 },
    { location_id: 3, city_name: "Cluj-Napoca", postal_code: "400001", department_id: 3, country: "Romania", lat: 46.7712, lng: 23.6236 },
    { location_id: 4, city_name: "Timisoara", postal_code: "300001", department_id: 3, country: "Romania", lat: 45.7489, lng: 21.2087 },
    { location_id: 5, city_name: "Craiova", postal_code: "200001", department_id: 4, country: "Romania", lat: 44.3302, lng: 23.7949 },
    { location_id: 6, city_name: "Brasov", postal_code: "500001", department_id: 3, country: "Romania", lat: 45.6427, lng: 25.5887 },
    { location_id: 7, city_name: "Constanta", postal_code: "900001", department_id: 1, country: "Romania", lat: 44.1598, lng: 28.6348 },
    { location_id: 8, city_name: "Galati", postal_code: "800001", department_id: 2, country: "Romania", lat: 45.4353, lng: 28.008 }
]);