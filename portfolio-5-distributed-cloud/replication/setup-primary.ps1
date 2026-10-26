# Run ONCE on the local primary (shopcave-pg) before starting the replica.
# It creates a replication user and lets that user connect for replication. Local dev only.
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Docker\Docker\resources\bin" }

docker exec shopcave-pg psql -U shopcave -d shopcave -c "DO `$`$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='replicator') THEN CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'repl_dev_only'; END IF; END `$`$;"

# allow replication connections from the Docker network (appended once)
docker exec shopcave-pg bash -c "grep -q 'host replication replicator' `$PGDATA/pg_hba.conf || echo 'host replication replicator all scram-sha-256' >> `$PGDATA/pg_hba.conf"
docker exec shopcave-pg psql -U shopcave -d shopcave -c "SELECT pg_reload_conf();"
docker exec shopcave-pg psql -U shopcave -d shopcave -tAc "SHOW wal_level; SHOW max_wal_senders;"
