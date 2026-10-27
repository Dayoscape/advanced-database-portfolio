# Portfolio 5: Analysis

## 1. Replication and availability
I ran a PostgreSQL primary (`shopcave-pg`) and a streaming replica (`shopcave-pg-replica`). The replica was built with `pg_basebackup -R` and then replays the primary's write-ahead log (WAL). Results (`outputs/01-replication.txt`):
- The primary listed the replica as `streaming` and `async`. **Asynchronous** means a commit on the primary does not wait for the replica.
- A table created and a row inserted on the primary appeared on the replica about a second later; writes sent to the replica were rejected (`read-only transaction`). The replica is useful for read scaling and as a hot standby, but not for writes.
- After a burst of 200,000 rows, the replica was about 1 second behind and then matched the primary. Replication lag is the price of asynchronous replication: a reader on the replica can briefly see old data.

**Failover** (`outputs/02-failover.txt`): I stopped the primary, ran `pg_promote()` on the replica, and the replica started accepting writes within seconds, so the shop could keep taking orders. When the old primary restarted, it did not have the row that was written to the new primary: the two servers had **diverged**. In a real system the old primary must not be allowed to accept writes again ("split brain") and would have to be rebuilt as a replica of the new primary. Also, because replication was asynchronous, any transaction committed on the primary but not yet replayed would have been lost in a real crash. I did not test that case.

## 2. Consistency in ShopCave (CAP and trade-offs)
CAP says that when the network between nodes fails (a partition), a system must choose between **consistency** (every read sees the latest write) and **availability** (every request gets an answer). Different parts of ShopCave should choose differently:

| Data | Choice | Why |
|---|---|---|
| Stock levels, payments, order placement | **Consistency** (single primary, row locks as in Portfolio 3; reject or wait during a failure) | Showing stale stock oversells; double-charging is a serious error |
| Product catalogue, search, reviews | **Availability** (read replicas, MongoDB, possibly stale) | A review or price that is a few seconds old does no harm, and these pages carry most of the traffic |
| Order history page | Read from a replica, accept a short delay, but read from the primary right after checkout ("read your own writes") | A customer who just paid would be confused if the order is not shown yet |

Synchronous replication (the primary waits for the replica to confirm) would remove the lost-transaction risk but slows every commit and stops writes if the replica is down. That is a consistency-versus-availability decision as well.

## 3. Partitioning and sharding
`outputs/03-partitioning.txt`. These tests were done on copies of `orders`, so the real tables were not changed. Note that partitioning splits a table **inside one server**, while real sharding spreads the pieces across several servers (for example with Citus). I used hash partitions to show how a shard key behaves; I did not set up multiple servers.

**Range partitioning by `placed_at` (10 quarterly partitions, the oldest one empty)**
- Partition pruning worked: a query for the last 90 days showed `Subplans Removed: 8`, so only the 2 newest partitions were read.
- It was **not faster** in my test (about 12 ms against 7 to 53 ms for the plain table, which varied between runs). The plain table had an index on `placed_at` and the partitioned copy had none, so the comparison is not fair, and I do not claim a speed-up for this query. The benefit I could demonstrate is **maintenance**: dropping the oldest partition (46,330 rows) took 2.9 ms against 81 ms for a `DELETE` of the same rows from a plain table, and it avoids leaving dead rows to vacuum.
- Downside: the partition key must be part of the primary key (`PRIMARY KEY (order_id, placed_at)`). Other tables with a foreign key to `orders` would also need the key, which is why I did not convert the real table.

**Hash partitioning by `customer_id` (4 shards)**
- The rows spread evenly (124,936 to 125,086 per shard), so `customer_id` is a good key for balance.
- A query on `customer_id` touched one shard. A query by date (no shard key) had to visit all four shards (scatter-gather).

| Possible shard key | Balance | Query fit | Risk |
|---|---|---|---|
| `customer_id` (hash) | Even (shown) | Customer order history reads one shard | Reports by date or seller visit every shard |
| `placed_at` (range) | Poor for writes: the newest partition takes all new orders (16,461 of the last 30 days' 19,340 orders went to the newest partition) | Date reports and retention are easy | Hot spot on the newest partition |
| Seller state | Skewed (Lagos would be much larger than other states in a real market) | Regional delivery queries | Hot shard; I did not measure this with data |

## 4. Cloud deployment
See `cloud-deployment.md`. I created a free Neon project (`shopcave-portfolio`, AWS Europe West 2, London) and loaded the same `schema.sql` into it. All 10 tables were created (`screenshots/02-cloud-tables.png`). Neon reported PostgreSQL 18.6, while my local Docker database runs PostgreSQL 16, so the same schema worked on a newer major version without changes.

What I observed in the Neon console (Free plan):
- **Setup:** creating the project and getting a connection string took a few minutes; I did not have to write any replication, user or server configuration (`screenshots/01-neon-dashboard.png`).
- **Backups:** the Backup & Restore page offers "Restore from history" to any point in a **6-hour window** (configurable), and manual snapshots. Scheduled snapshots show "Upgrade for schedules", so they need a paid plan (`screenshots/03-backups.png`).
- **Scaling:** the compute is sized **0.25 to 2 CU** (it scales automatically within that range) and showed **SUSPENDED** a few minutes after I stopped using it, meaning it scales to zero when idle, so the first connection after a pause is likely to be slower (I did not time this). A **Read Replica** option is listed on the page; I did not create one, so I cannot say what it costs or whether the free plan allows it (`screenshots/04-scaling-options.png`).

| | Self-hosted (my Docker setup) | Managed PostgreSQL (Neon, Free plan) |
|---|---|---|
| Setup | I wrote the compose files, replication user and entrypoint script | A few clicks, then a connection string |
| Replication and failover | I configured replication and promoted the replica by hand | A read-replica option exists in the console (not tested); I did not test failover |
| Backups | None configured by me | 6-hour point-in-time restore window and manual snapshots; scheduled snapshots need a paid plan |
| Scaling | Fixed by my laptop | Autoscaling compute (0.25 to 2 CU) and suspend when idle |
| Control | Full (I could edit `pg_hba.conf`, stop the primary, promote the replica) | Limited to what the console and roles allow; I did not need superuser access |
| Cost and effort | Free, but my time and my laptop; nothing keeps it running if my PC is off | Free plan with limits; I have not checked the paid pricing |

**What this means for ShopCave:** a managed service takes over the backup and operations work that I did by hand, and it removes the single laptop as a point of failure, but the free plan's 6-hour history, suspend-when-idle behaviour and lack of scheduled snapshots would not be enough for a real shop's order and payment data. For production I would need a paid plan with longer retention and high availability, and I would check the pricing and the replica options before choosing.

## Limits
- Everything ran on one laptop, so there is no real network partition, latency or hardware failure; the "crash" was `docker stop`.
- Replication was asynchronous only. I did not test synchronous replication, a crash with unreplicated transactions, or rebuilding the old primary as a replica.
- Partitioning demos use copies and single runs; timings are noisy.

---
*Drafted by Claude from the recorded outputs. Rewrite in your own words and make sure you can explain each experiment before submitting. Section 4 uses what I saw in the Neon console; check each statement against your screenshots.*
