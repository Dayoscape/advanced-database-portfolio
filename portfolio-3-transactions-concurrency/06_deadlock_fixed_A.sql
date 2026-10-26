-- Demo 6 (the FIX): every transaction locks products in the SAME order (X before Y). Session A.
\echo 'A: locking X then Y'
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item X';
SELECT pg_sleep(2);
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item Y';
COMMIT;
\echo 'A: finished'
