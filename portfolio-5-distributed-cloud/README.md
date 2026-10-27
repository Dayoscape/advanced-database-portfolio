# Portfolio 5: Distributed and Cloud Database

Same case study (ShopCave). Everything below ran locally in Docker except the cloud part, which needs your own account (see `cloud-deployment.md`).

## Contents
| Part | Files | Evidence |
|---|---|---|
| Replication | `../docker-compose.replica.yml`, `replication/setup-primary.ps1`, `replication/replica-entrypoint.sh`, `replication/01-replication-demo.ps1` | `outputs/01-replication.txt` |
| Failover | `replication/02-failover-demo.ps1` | `outputs/02-failover.txt` |
| Partitioning / sharding | `partitioning.sql` | `outputs/03-partitioning.txt` |
| Consistency, availability, CAP; self-hosted vs managed | `analysis.md` | |
| Cloud deployment (Neon, Free plan) | `cloud-deployment.md` | `screenshots/01-neon-dashboard.png` to `04-scaling-options.png` |

## How to run (PowerShell)
```bash
# from the repository root, once:
.\portfolio-5-distributed-cloud\replication\setup-primary.ps1
docker compose -f docker-compose.yml -f docker-compose.replica.yml up -d postgres-replica
# then:
.\portfolio-5-distributed-cloud\replication\01-replication-demo.ps1
.\portfolio-5-distributed-cloud\replication\02-failover-demo.ps1      # stops the primary briefly, then restores and removes the replica
Get-Content portfolio-5-distributed-cloud\partitioning.sql -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave
```
Run the failover demo last: it removes the replica when it finishes.

## Results in one table
| Experiment | Result |
|---|---|
| Streaming replication | Replica reported `streaming`, `async`; it held all 500,000 orders |
| Write on replica | `ERROR: cannot execute INSERT in a read-only transaction` |
| Lag after a 200,000-row burst | `replay_lag` about 0.95 s, replica count equal to primary within 2 s |
| Failover | Primary stopped, `pg_promote()` made the replica writable; the old primary did NOT get the row written on the new primary (split brain) |
| Range partitioning by quarter | Query for the last 90 days: `Subplans Removed: 8` (8 of the 10 partitions were skipped; only the 2 newest were scanned) |
| Drop old partition vs DELETE | `DROP TABLE` of a 46,330-row partition: 2.9 ms; `DELETE` of the same rows from a plain table: 81 ms |
| Hash partitioning by customer_id | 4 shards with 124,936 to 125,086 rows each; a query on `customer_id` touched one shard, a query without it touched all four |
