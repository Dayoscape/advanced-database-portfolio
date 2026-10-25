-- Q4: sellers with the highest share of failed deliveries (at least 200 delivered-or-failed orders)
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.seller_id, s.business_name,
       count(DISTINCT d.order_id) AS deliveries_total,
       round(100.0 * count(DISTINCT d.order_id) FILTER (WHERE d.status = 'failed')
             / count(DISTINCT d.order_id), 2) AS failed_pct
FROM sellers s
JOIN products p ON p.seller_id = s.seller_id
JOIN order_items oi ON oi.product_id = p.product_id
JOIN deliveries d ON d.order_id = oi.order_id
WHERE d.status IN ('delivered', 'failed')
GROUP BY s.seller_id, s.business_name
HAVING count(DISTINCT d.order_id) >= 200
ORDER BY failed_pct DESC
LIMIT 10;
