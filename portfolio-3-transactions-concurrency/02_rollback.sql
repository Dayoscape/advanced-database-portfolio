-- Demo 2: ROLLBACK. The payment fails, so everything done for the order is undone.
\echo '--- before: stock of DEMO Item X'
SELECT stock_qty FROM products WHERE name = 'DEMO Item X';

BEGIN;
WITH o AS (
  INSERT INTO orders (customer_id, address_id)
  SELECT c.customer_id, a.address_id FROM customers c JOIN addresses a USING (customer_id)
  WHERE c.email = 'demo-buyer-a@example.test'
  RETURNING order_id)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 2, p.unit_price FROM o, products p WHERE p.name = 'DEMO Item X';

UPDATE products SET stock_qty = stock_qty - 2 WHERE name = 'DEMO Item X';

\echo '--- inside the transaction (before the payment result): order and reduced stock are visible to this session'
SELECT stock_qty FROM products WHERE name = 'DEMO Item X';
SELECT count(*) AS orders_for_buyer_a FROM orders o JOIN customers c USING (customer_id) WHERE c.email = 'demo-buyer-a@example.test';

\echo '--- payment gateway reports FAILURE, so ROLLBACK'
ROLLBACK;

\echo '--- after ROLLBACK: stock is back to 10 and no order exists'
SELECT stock_qty FROM products WHERE name = 'DEMO Item X';
SELECT count(*) AS orders_for_buyer_a FROM orders o JOIN customers c USING (customer_id) WHERE c.email = 'demo-buyer-a@example.test';
