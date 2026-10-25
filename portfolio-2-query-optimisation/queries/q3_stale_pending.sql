-- Q3: pending orders older than 7 days (a small slice of the table, good for a partial index)
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, placed_at
FROM orders
WHERE status = 'pending'
  AND placed_at < now() - interval '7 days'
ORDER BY placed_at
LIMIT 50;
