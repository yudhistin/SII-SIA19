// ============================================================
// DS3: MongoDB 6.0 - For-Sale Listings (Realtor.com)
// SII-SIA19: Integrated Real Estate Market Analysis System
//
// Dataset: USA Real Estate Dataset (Realtor.com listings)
// Source : https://www.kaggle.com/datasets/ahmedshahriarsakib/usa-real-estate-dataset
// File   : realtor-data.zip.csv  (~2.2M listings, US-wide)
// Volume : Recommended import: 200k random sample for lab use
// Role   : Active FOR-SALE listings (current market inventory)
// ============================================================

// Pas 1: Convert the Kaggle CSV to JSON (one-off, host machine)
//   Use any CSV->JSON tool, e.g. Python:
//     import pandas as pd
//     df = pd.read_csv('realtor-data.zip.csv')
//     df.sample(200000, random_state=19).to_json(
//         'realtor_listings.json', orient='records', lines=True)

// Pas 2: Copy the JSON into the Mongo container
//   docker cp realtor_listings.json mongodb-6.0:/tmp/

// Pas 3: Import (run in host shell, NOT mongosh)
//   docker exec -it mongodb-6.0 mongoimport \
//     --db realestate \
//     --collection forsale \
//     --type json \
//     --file /tmp/realtor_listings.json \
//     --numInsertionWorkers 4

// Pas 4: Verify (mongosh)
use realestate

db.forsale.countDocuments()
// Expected: ~200,000 (or full 2.2M if you imported the whole dataset)

// Sample document - confirm schema
db.forsale.findOne()
// Expected fields: brokered_by, status, price, bed, bath, acre_lot, street,
//                  city, state, zip_code, house_size, prev_sold_date

// Pas 5: Indexes for the analytical workload
db.forsale.createIndex({ state: 1, city: 1 })
db.forsale.createIndex({ status: 1 })
db.forsale.createIndex({ price: 1 })
db.forsale.createIndex({ zip_code: 1 })
db.forsale.createIndex({ brokered_by: 1 })

// Pas 6: Sample analytical aggregations

// 6.1 - Median listing price by state, top 15
db.forsale.aggregate([
    { $match: { status: "for_sale", price: { $gt: 0 } } },
    { $group: {
        _id: "$state",
        nr_listings: { $sum: 1 },
        avg_price: { $avg: "$price" },
        avg_size:  { $avg: "$house_size" },
        avg_bed:   { $avg: "$bed" }
    }},
    { $sort: { avg_price: -1 } },
    { $limit: 15 }
])

// 6.2 - Top 10 brokers (acting as Agents in our domain) by inventory
db.forsale.aggregate([
    { $match: { status: "for_sale", brokered_by: { $ne: null } } },
    { $group: {
        _id: "$brokered_by",
        nr_listings: { $sum: 1 },
        total_value: { $sum: "$price" }
    }},
    { $sort: { nr_listings: -1 } },
    { $limit: 10 }
])

// 6.3 - Price-per-square-foot by state
db.forsale.aggregate([
    { $match: {
        status: "for_sale",
        price: { $gt: 0 },
        house_size: { $gt: 0 }
    }},
    { $project: {
        state: 1,
        ppsf: { $divide: ["$price", "$house_size"] }
    }},
    { $group: {
        _id: "$state",
        avg_ppsf: { $avg: "$ppsf" },
        count: { $sum: 1 }
    }},
    { $match: { count: { $gte: 100 } } },
    { $sort: { avg_ppsf: -1 } },
    { $limit: 15
    }
])

// Pas 7: Export a JSON-array slice for cross-engine work (Oracle / Spark)
//   docker exec -it mongodb-6.0 mongoexport \
//     --db realestate \
//     --collection forsale \
//     --query '{ "status": "for_sale" }' \
//     --limit 5000 \
//     --jsonArray \
//     --out /tmp/forsale_sample.json
//
//   docker cp mongodb-6.0:/tmp/forsale_sample.json ./
