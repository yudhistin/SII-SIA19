#!/bin/bash
# Auto-runs on first boot of the mongo container.
# Loads realtor_listings.jsonl into realestate.forsale.

set -e

JSONL=/data/source/realtor_listings.jsonl
if [ ! -f "$JSONL" ]; then
    echo "[mongo-init] $JSONL not found - skip seeding."
    echo "[mongo-init] Run 1_Data_Sources/prepare_data.py and re-create the volume."
    exit 0
fi

echo "[mongo-init] Importing $JSONL ..."
mongoimport \
    --db realestate \
    --collection forsale \
    --file "$JSONL" \
    --numInsertionWorkers 4 \
    --quiet

echo "[mongo-init] Creating indexes..."
mongosh realestate --quiet --eval '
    db.forsale.createIndex({ state: 1, city: 1 });
    db.forsale.createIndex({ status: 1 });
    db.forsale.createIndex({ price: 1 });
    db.forsale.createIndex({ zip_code: 1 });
    db.forsale.createIndex({ brokered_by: 1 });
    print("docs: " + db.forsale.countDocuments());
'

echo "[mongo-init] Done."
