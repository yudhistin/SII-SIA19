# Docker stack - SII-SIA19

Six containers reproducing the federation environment on any machine with Docker Desktop.

## Bring up

```cmd
cp .env.example .env       :: edit if needed
docker compose up -d
```

Wait ~2 min for Oracle to finish initializing (`docker logs -f oracle-xe-21c` shows `DATABASE IS READY TO USE!`). Postgres + Mongo seed themselves on the first boot from `1_Data_Sources/`.

## Seed data

`prepare_data.py` (in `1_Data_Sources/`) must be run **before** the first `docker compose up` so the CSV/JSONL files exist for the Postgres + Mongo init scripts.

| Container | What seeds | Trigger |
|-----------|------------|---------|
| postgresql-container | rentals schema + listings CSV | `docker/postgres-init/*` runs once on empty volume |
| mongodb-6.0 | realestate.forsale collection from JSONL | `docker/mongo-init/*` runs once on empty volume |
| neo4j | geo hierarchy | run `18_DS_Neo4J_GeoHierarchy.cypher` manually in Neo4j Browser at http://localhost:7474 |
| oracle-xe-21c | NYC sales + macro CSV via FDBO | run the `1_Data_Sources/11_*.sql` and `13_*_load.sql` from SQL Developer |

If you wipe the volumes (`docker compose down -v`) the Postgres and Mongo seeds run again automatically; Oracle and Neo4j need re-loading manually.

## Networking notes

- All six containers share the `realestate` bridge network; they can reach each other by container name (e.g. `postgrest -> postgresql-container:5432`).
- Oracle's `UTL_HTTP` calls use `host.docker.internal:<port>` because that's what the SQL files in `2_Access_Model/` already reference. Docker Desktop maps it to the Windows host, which then forwards to the published ports of the other containers.
- If you ever flatten everything onto the same compose network, you can replace `host.docker.internal` with the container names (`postgrest`, `restheart`, `neo4j`) in the access scripts and skip the host-level round trip.

## Health checks

```cmd
curl http://localhost:3000/listing?limit=1            :: PostgREST
curl http://localhost:8080/realestate/forsale?pagesize=1   :: RESTHeart  (admin:secret)
curl http://localhost:7474                            :: Neo4j HTTP
```

If any of these return connection refused, give it another 10-30 s and retry; the dependent containers wait for their backends to be healthy before starting.

## Stop / cleanup

```cmd
docker compose stop                 :: pause containers (keep state)
docker compose down                 :: remove containers (keep volumes)
docker compose down -v              :: nuke volumes too (full reset)
```
