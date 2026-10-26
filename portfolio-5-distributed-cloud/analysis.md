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
See `cloud-deployment.md`. The table below is based on what I ran locally and on general knowledge of managed services; I have not yet checked it against a cloud service myself, so complete it after the cloud exercise.

| | Self-hosted (my Docker setup) | Managed PostgreSQL (for example Supabase or Neon) |
|---|---|---|
| Setup | I wrote the compose files, replication user and entrypoint script | A few clicks |
| Replication and failover | I configured and promoted manually | Usually provided by the service (depends on plan) |
| Backups | None configured by me | Usually automatic (depends on plan) |
| Control | Full | Limited settings, some extensions restricted |
| Cost and effort | Free but my time and my laptop | Free tier with limits; paid plans for production |

## Limits
- Everything ran on one laptop, so there is no real network partition, latency or hardware failure; the "crash" was `docker stop`.
- Replication was asynchronous only. I did not test synchronous replication, a crash with unreplicated transactions, or rebuilding the old primary as a replica.
- Partitioning demos use copies and single runs; timings are noisy.

---
*Drafted by Claude from the recorded outputs. Rewrite in your own words and make sure you can explain each experiment before submitting. Complete section 4 after the cloud exercise.*
