-- Q1: a customer's order history with the total of each order
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.placed_at, o.status,
       SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.customer_id = 12345
GROUP BY o.order_id, o.placed_at, o.status
ORDER BY o.placed_at DESC;
