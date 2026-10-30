# Study sheet: explaining my ShopCave portfolio

Use this to prepare for a possible verification discussion. Read each section, close the file, then try to answer the questions out loud in your own words. If you cannot, open the file named in brackets and run the demo again.

The numbers below come from my own runs and the saved outputs in the repository.

---

## Portfolio 1: Design and normalisation  (`portfolio-1-database-design/`)

**One-minute explanation.** ShopCave is an online marketplace. I started from one big spreadsheet row per order and split it into 10 tables so each fact is stored once. Customers have addresses and orders; orders contain products through `order_items`; each order has payments and one delivery; products belong to a seller and a category and have reviews.

**Likely questions**
1. *What is 1NF, 2NF, 3NF in your design?*
   1NF: one value per cell (each item on its own row). 2NF: no column depends on only part of the composite key (`order_id, product_id`), so order data and product data were split out. 3NF: no column depends on another non-key column, so customers, addresses, sellers and categories became their own tables.
2. *Why does `order_items` have its own `unit_price`?* It is the price on the day of the sale. `products.unit_price` is the current price. Without it, a price change would rewrite old orders. It is a different fact, so it is not redundancy.
3. *Why no stored order total?* It can be calculated with SUM(quantity x unit_price). A stored copy could get out of step with the items (an update anomaly).
4. *Why is `deliveries.order_id` UNIQUE but `payments.order_id` not?* One delivery per order, but a payment can fail and be retried.
5. *Name two constraints and why.* `CHECK (stock_qty >= 0)` stops negative stock; `UNIQUE (product_id, customer_id)` on reviews allows one review per customer per product.
6. *What is the composite primary key for?* `order_items(order_id, product_id)` resolves the many-to-many between orders and products.

---

## Portfolio 2: Query optimisation  (`portfolio-2-query-optimisation/`)

**One-minute explanation.** I generated 500,000 orders and about 1.25 million order items, wrote five queries, and recorded their plans with `EXPLAIN (ANALYZE, BUFFERS)` before and after adding indexes. Indexes helped queries that pick a small part of a table, and did not help queries that need most of it.

**Numbers:** Q1 25.5 ms to 3.4 ms (composite index on `orders(customer_id, placed_at)`); Q3 30.3 ms to 0.28 ms (partial index on pending orders, about 5% of rows); Q2, Q4 and Q5 no real change.

**Likely questions**
1. *What does a Seq Scan versus an Index Scan mean?* Seq Scan reads every row; Index Scan uses the index to jump to the matching rows.
2. *Why did Q3 improve so much?* The partial index (`WHERE status = 'pending'`) holds only about 5% of the rows, so it is small, and the query reads it in date order and stops after 50 rows.
3. *Why did Q2 and Q4 not improve?* They total up a large share of `order_items` and `deliveries`. Reading a big part of a table in one pass is cheaper than jumping around through an index, so the planner correctly ignored the indexes.
4. *Why was the covering index on reviews never used?* The query has to read all 150,000 small review rows to average them, so a sequential scan is already cheap. I thought VACUUM would fix it, tested it, and it did not.
5. *Why are your timings different between runs?* Cache state and other programs. Q2 ranged from 197 to 840 ms with the same plan, so I trust plans and row counts more than single timings.
6. *What would you do to speed up Q2 and Q4?* A summary table (revenue per product per month), or partitioning, or pre-aggregating.

---

## Portfolio 3: Transactions and concurrency  (`portfolio-3-transactions-concurrency/`)

**One-minute explanation.** A transaction makes several steps all-or-nothing. I showed commit, rollback, a real concurrency bug (overselling), its fix, isolation levels, and a deadlock with its fix. The DEMO rows keep the 500k-order data untouched.

**Likely questions**
1. *What happened in the oversell demo?* Both buyers read stock = 1 before either wrote, both passed the check, both placed an order and both wrote `stock = 0`. Result: 2 orders for 1 unit (a lost update).
2. *How did `FOR UPDATE` fix it?* It locks the product row when it is read. The second buyer waits until the first commits, then reads stock = 0 and is rejected.
3. *Why did the CHECK constraint not stop it?* The code wrote an absolute value (0), not `stock - 1`, so the check never saw a negative number.
4. *What is the difference between READ COMMITTED and REPEATABLE READ?* In READ COMMITTED each statement sees the latest committed data, so my transaction read 1000 and then 1500. In REPEATABLE READ the transaction keeps its first snapshot, so it read 1000 both times.
5. *What is MVCC?* PostgreSQL keeps several versions of a row so readers do not block writers, and each transaction sees the version that matches its snapshot.
6. *What caused the deadlock and what was the fix?* A locked X then wanted Y; B locked Y then wanted X; each waited for the other. PostgreSQL detected the cycle and aborted one transaction. Fix: everyone locks rows in the same order.

---

## Portfolio 4: NoSQL  (`portfolio-4-nosql/`)

**One-minute explanation.** Products do not share the same attributes (a phone has RAM, a shirt has a size). A document database holds only the attributes that apply, with no joins and no table of NULLs. I stored products and orders as MongoDB documents and kept stock and payments in PostgreSQL.

**Likely questions**
1. *Why MongoDB for the catalogue?* Variable attributes per category; the SQL alternatives are a wide table full of NULLs or an entity-attribute-value table that needs a self-join per attribute.
2. *What did you embed and what did you reference?* Embedded: order items, address and payment inside an order, and the latest reviews inside a product (always read together). Referenced: `sellerId` (a seller has many products and changes independently).
3. *Why copy the product name and price into the order items?* It is a snapshot of what was bought, like `unit_price` in SQL.
4. *What do you lose compared with PostgreSQL?* Enforced constraints and foreign keys, easy joins, and strong cross-document transactions. So stock and payments stay in PostgreSQL.
5. *Explain the index results.* The customer-orders lookup went from examining 100,000 documents to 2 (about 1 ms). Black size-M shirts went to 1,207 documents. The "bestseller" tag matched 27% of products, so the index helped little. Timings differed between my two runs, so I rely on documents examined.
6. *What is COLLSCAN and IXSCAN?* A full collection scan versus an index scan in the MongoDB explain output.

---

## Portfolio 5: Distributed and cloud  (`portfolio-5-distributed-cloud/`)

**One-minute explanation.** I ran a primary and a replica, promoted the replica to show failover, partitioned order data, and loaded the schema into a managed cloud database. The ideas are replication for availability and read scaling, partitioning for maintenance and scale, and the consistency versus availability trade-off.

**Likely questions**
1. *What is asynchronous replication and what is its risk?* The primary does not wait for the replica. The replica can be briefly behind (about 1 second after my 200,000-row burst), and in a real crash, committed but unreplicated transactions could be lost.
2. *What happened at failover?* I stopped the primary and ran `pg_promote()` on the replica, which then accepted writes. The old primary came back without that new row. The servers had diverged (split brain), so in real life the old primary must be rebuilt as a replica.
3. *Partitioning versus sharding?* Partitioning splits a table inside one server; sharding spreads the pieces over several servers. I used hash partitions to show how a shard key behaves, but I did not run multiple servers.
4. *What did range partitioning achieve?* Partition pruning skipped 8 of 10 partitions for a last-90-days query, and dropping an old partition took 2.9 ms against 81 ms for the same DELETE. It was not faster for the query, because my comparison table had an index and the partitioned copy did not.
5. *Why is `customer_id` a good shard key but `placed_at` a poor one?* The customer hash gave four even shards (about 125,000 rows each), while all new orders land in the newest date partition (a hot spot).
6. *CAP in ShopCave?* Stock and payments favour consistency (reject or wait during a failure). The catalogue and reviews favour availability (replicas, slightly stale data is acceptable). Read your own writes from the primary right after checkout.
7. *What did the cloud exercise show?* The same schema loaded unchanged on Neon (PostgreSQL 18, Free plan). I saw a 6-hour restore window, manual snapshots (scheduled ones need a paid plan), and compute that suspends when idle. I saw a read-replica option but did not test it.

---

## If asked about AI use
Be honest and specific: Claude drafted the scaffolding, scripts and first drafts of the write-ups; you ran the demos, took the screenshots, created the cloud project and corrected results that differed from the drafts (for example the MongoDB timings). Do not claim work you did not do, and do not claim to understand something you cannot explain. Say "I would check the output" if you are unsure.
