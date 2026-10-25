-- Q2: top 10 products by revenue in one month (cancelled orders excluded)
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_id, p.name,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.placed_at >= now() - interval '90 days'
  AND o.placed_at <  now() - interval '60 days'
  AND o.status <> 'cancelled'
GROUP BY p.product_id, p.name
ORDER BY revenue DESC
LIMIT 10;
