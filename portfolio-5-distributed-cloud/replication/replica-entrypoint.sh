#!/bin/bash
# Replica start-up: on first run copy the primary with pg_basebackup (-R writes standby.signal
# and the connection settings), then start PostgreSQL as a read-only standby.
set -e
PGDATA=/var/lib/postgresql/data
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Replica: taking base backup from shopcave-pg ..."
  chown postgres:postgres "$PGDATA"
  chmod 700 "$PGDATA"
  gosu postgres env PGPASSWORD=repl_dev_only \
    pg_basebackup -h shopcave-pg -U replicator -D "$PGDATA" -R -X stream -P
fi
exec docker-entrypoint.sh postgres
