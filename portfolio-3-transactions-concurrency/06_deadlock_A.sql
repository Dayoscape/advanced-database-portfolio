-- Demo 6 (the PROBLEM): session A locks X, then wants Y.
\echo 'A: locking X'
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item X';
SELECT pg_sleep(2);
\echo 'A: now wants Y (B holds it)'
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item Y';
COMMIT;
\echo 'A: finished'
