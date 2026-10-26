-- Demo 4 (the FIX): session B = Buyer B. It blocks on FOR UPDATE until A commits, then sees stock = 0.
\echo 'Buyer B: start (will wait for the lock)'
BEGIN;
SELECT stock_qty >= 1 AS ok, stock_qty AS s FROM products WHERE name = 'DEMO Last Unit' FOR UPDATE \gset
\echo 'Buyer B sees stock =' :s
\if :ok
  WITH o AS (
    INSERT INTO orders (customer_id, address_id)
    SELECT c.customer_id, a.address_id FROM customers c JOIN addresses a USING (customer_id)
    WHERE c.email = 'demo-buyer-b@example.test'
    RETURNING order_id)
  INSERT INTO order_items (order_id, product_id, quantity, unit_price)
  SELECT o.order_id, p.product_id, 1, p.unit_price FROM o, products p WHERE p.name = 'DEMO Last Unit';
  UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Last Unit';
  \echo 'Buyer B: ORDER PLACED'
\else
  \echo 'Buyer B: out of stock, rejected'
\endif
COMMIT;
