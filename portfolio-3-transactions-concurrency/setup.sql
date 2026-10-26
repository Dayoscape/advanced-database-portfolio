-- Resets the demo data. Safe to run repeatedly. Only touches rows named DEMO / demo-buyer-*.
DELETE FROM payments WHERE order_id IN
  (SELECT o.order_id FROM orders o JOIN customers c USING (customer_id) WHERE c.email LIKE 'demo-buyer-%');
DELETE FROM orders WHERE customer_id IN (SELECT customer_id FROM customers WHERE email LIKE 'demo-buyer-%');
DELETE FROM addresses WHERE customer_id IN (SELECT customer_id FROM customers WHERE email LIKE 'demo-buyer-%');
DELETE FROM customers WHERE email LIKE 'demo-buyer-%';
DELETE FROM products WHERE name LIKE 'DEMO%';

INSERT INTO customers (full_name, email) VALUES
  ('DEMO Buyer A', 'demo-buyer-a@example.test'),
  ('DEMO Buyer B', 'demo-buyer-b@example.test');

INSERT INTO addresses (customer_id, street, city, state, is_default)
SELECT customer_id, '1 Demo Street', 'Demo City', 'Lagos', true
FROM customers WHERE email LIKE 'demo-buyer-%';

INSERT INTO products (seller_id, category_id, name, unit_price, stock_qty) VALUES
  (1, 1, 'DEMO Last Unit', 1000, 1),
  (1, 1, 'DEMO Item X',    1000, 10),
  (1, 1, 'DEMO Item Y',    1000, 10);
