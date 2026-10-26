\echo '=== FINAL STATE ==='
SELECT name, stock_qty, unit_price FROM products WHERE name LIKE 'DEMO%' ORDER BY name;
SELECT c.email AS buyer, o.order_id, p.name AS product, oi.quantity
FROM orders o
JOIN customers c USING (customer_id)
JOIN order_items oi USING (order_id)
JOIN products p USING (product_id)
WHERE c.email LIKE 'demo-buyer-%'
ORDER BY o.order_id;
