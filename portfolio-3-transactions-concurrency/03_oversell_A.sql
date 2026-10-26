-- Demo 3 (the PROBLEM): two buyers want the last unit, no locking. Session A = Buyer A.
-- Check-then-write pattern: read the stock, think for 3 seconds (e.g. fraud check), then write.
\echo 'Buyer A: start'
BEGIN;
SELECT stock_qty >= 1 AS ok, stock_qty AS s FROM products WHERE name = 'DEMO Last Unit' \gset
\echo 'Buyer A sees stock =' :s
SELECT pg_sleep(3);
\if :ok
  WITH o AS (
    INSERT INTO orders (customer_id, address_id)
    SELECT c.customer_id, a.address_id FROM customers c JOIN addresses a USING (customer_id)
    WHERE c.email = 'demo-buyer-a@example.test'
    RETURNING order_id)
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  SELECT o.order_id, p.product_id, 1, p.unit_price FROM o, products p WHERE p.name = 'DEMO Last Unit';
  UPDATE products SET stock_qty = :s - 1 WHERE name = 'DEMO Last Unit';
  \echo 'Buyer A: ORDER PLACED'
\else
  \echo 'Buyer A: out of stock, rejected'
\endif
COMMIT;
