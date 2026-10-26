-- Demo 1: COMMIT. Place an order as ONE transaction: create order, add item, reduce stock.
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
COMMIT;

\echo '--- after COMMIT: stock reduced by 2 and the order exists (see final state below)'
