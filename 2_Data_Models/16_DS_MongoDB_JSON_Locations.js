// ============================================================
// DS4: MongoDB 6.0 -- Import Online Retail dataset
// SII-SIA19: Retail Sales Federated Analysis System
// Dataset: online_retail_II.xlsx (Kaggle, 541910 documents)
// ============================================================
 
// Pas 1: Salveaza online_retail_II.xlsx ca CSV din Excel
// File -> Save As -> CSV (Comma delimited) -> online_retail.csv
 
// Pas 2: Copiaza CSV-ul in containerul MongoDB
// docker cp "C:\Users\YudHistin\SII-SIA19\1_Data_Sources\online_retail.csv" mongodb-6.0:/tmp/
 
// Pas 3: Import in MongoDB
// docker exec -it mongodb-6.0 mongoimport \
//   --db mds \
//   --collection OnlineRetail \
//   --type csv \
//   --headerline \
//   --file /tmp/online_retail.csv \
//   --numInsertionWorkers 4
 
// Pas 4: Verifica importul
// docker exec -it mongodb-6.0 mongosh mds --eval "db.OnlineRetail.countDocuments()"
// Expected: 541910
 
// Pas 5: Export sample 1000 documente ca JSON array pentru Oracle
// docker exec -it mongodb-6.0 mongoexport \
//   --db mds \
//   --collection OnlineRetail \
//   --limit 1000 \
//   --jsonArray \
//   --out /tmp/online_retail_array.json
 
// Pas 6: Copiaza JSON-ul la Oracle (prin Windows)
// docker cp mongodb-6.0:/tmp/online_retail_array.json "C:\Users\YudHistin\SII-SIA19\1_Data_Sources\online_retail_array.json"
// docker cp "C:\Users\YudHistin\SII-SIA19\1_Data_Sources\online_retail_array.json" oracle-xe-21c:/opt/oracle/oradata/
 
// Verificari in mongosh:
use mds
 
// Numar total documente
db.OnlineRetail.countDocuments()
 
// Sample 3 documente
db.OnlineRetail.find().limit(3).pretty()
 
// Agregare: top tari dupa vanzari
db.OnlineRetail.aggregate([
    { $group: {
        _id: "$Country",
        total_quantity: { $sum: "$Quantity" },
        total_revenue: { $sum: { $multiply: ["$Quantity", "$Price"] } },
        count: { $sum: 1 }
    }},
    { $sort: { total_revenue: -1 } },
    { $limit: 10 }
])
 
// Verificare structura document
db.OnlineRetail.findOne()
// Expected fields: Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country