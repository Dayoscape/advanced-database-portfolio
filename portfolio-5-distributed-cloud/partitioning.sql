-- Partitioning demo on COPIES of orders (the real orders table and its foreign keys are not touched).
-- Run:  Get-Content partitioning.sql -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave
\set ON_ERROR_STOP on
DROP TABLE IF EXISTS orders_by_month, orders_by_customer CASCADE;

\echo '=== A. RANGE partitioning by placed_at (one partition per quarter)'
CREATE TABLE orders_by_month (
    order_id    BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    address_id  BIGINT NOT NULL,
    status      VARCHAR(20) NOT NULL,
    placed_at   TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (order_id, placed_at)          -- the partition key must be part of the primary key
) PARTITION BY RANGE (placed_at);

DO $$
DECLARE q date := date '2024-07-01';
BEGIN
  WHILE q < date '2027-01-01' LOOP
    EXECUTE format('CREATE TABLE %I PARTITION OF orders_by_month FOR VALUES FROM (%L) TO (%L)',
                   'orders_' || to_char(q, 'YYYY') || 'q' || to_char(q, 'Q'), q, q + interval '3 months');
    q := (q + interval '3 months')::date;
  END LOOP;
END $$;

INSERT INTO orders_by_month SELECT order_id, customer_id, address_id, status, placed_at FROM orders;
ANALYZE orders_by_month;

\echo 'rows per partition:'
SELECT tableoid::regclass AS partition, count(*) AS rows FROM orders_by_month GROUP BY 1 ORDER BY 1;

\echo '--- same query on the ordinary orders table (one big table, uses idx_orders_placed_at)'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON)
SELECT count(*) FROM orders WHERE placed_at >= now() - interval '90 days';

\echo '--- same query on the partitioned copy: partition pruning (only the recent partitions are scanned)'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON)
SELECT count(*) FROM orders_by_month WHERE placed_at >= now() - interval '90 days';

\echo '--- retention: removing the oldest quarter (46k rows) by dropping its partition'
SELECT count(*) AS rows_in_oldest_partition FROM orders_2024q4;
\timing on
DROP TABLE orders_2024q4;
\timing off
SELECT count(*) AS rows_left FROM orders_by_month;

\echo '--- for comparison: DELETE the same 46k rows from a PLAIN (non-partitioned) copy of the same shape'
CREATE TABLE orders_plain_copy (LIKE orders_by_month INCLUDING ALL);
INSERT INTO orders_plain_copy SELECT order_id, customer_id, address_id, status, placed_at FROM orders;
ANALYZE orders_plain_copy;
\timing on
DELETE FROM orders_plain_copy WHERE placed_at < date '2025-01-01';
\timing off
SELECT count(*) AS rows_left_plain FROM orders_plain_copy;
DROP TABLE orders_plain_copy;

\echo ''
\echo '=== B. HASH partitioning by customer_id: the idea behind sharding (4 "shards")'
CREATE TABLE orders_by_customer (
    order_id    BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    placed_at   TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (order_id, customer_id)
) PARTITION BY HASH (customer_id);
CREATE TABLE orders_shard0 PARTITION OF orders_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE orders_shard1 PARTITION OF orders_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE orders_shard2 PARTITION OF orders_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE orders_shard3 PARTITION OF orders_by_customer FOR VALUES WITH (MODULUS 4, REMAINDER 3);
INSERT INTO orders_by_customer SELECT order_id, customer_id, placed_at FROM orders;
ANALYZE orders_by_customer;

\echo 'rows per shard (even spread = good shard key):'
SELECT tableoid::regclass AS shard, count(*) AS rows FROM orders_by_customer GROUP BY 1 ORDER BY 1;

\echo '--- a query on the shard key touches ONE shard only'
EXPLAIN (COSTS OFF) SELECT * FROM orders_by_customer WHERE customer_id = 12345;

\echo '--- a query WITHOUT the shard key must ask every shard (scatter-gather)'
EXPLAIN (COSTS OFF) SELECT count(*) FROM orders_by_customer WHERE placed_at >= now() - interval '7 days';

\echo '--- hot-spot check for the range key: where do the newest orders land?'
SELECT tableoid::regclass AS partition, count(*) AS orders_in_last_30_days
FROM orders_by_month WHERE placed_at >= now() - interval '30 days' GROUP BY 1;

DROP TABLE orders_by_month, orders_by_customer CASCADE;
\echo 'demo tables dropped'
