# Portfolio 5: Distributed and Cloud Database

## Plan
- **Replication:** primary plus streaming replica via Docker Compose; show writes on primary, reads on replica, replication lag, and failover (promote the replica)
- **Sharding / partitioning:** shard `orders` by customer or region; show the shard-key choice and hot-spot risk (declarative partitioning, or Citus if time allows)
- **CAP / consistency discussion** for ShopCave: strong consistency for stock and payments, eventual for reviews and catalogue search
- **Cloud deployment evidence:** managed Postgres free tier (Supabase or Neon) with connection and backup/PITR screenshots
- Short comparison table: self-hosted vs managed

Evidence: `docker-compose.replica.yml`, configs, command output, screenshots.
