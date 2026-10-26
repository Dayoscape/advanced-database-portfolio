-- Demo 6 (the PROBLEM): session B locks Y, then wants X (the opposite order to A).
\echo 'B: locking Y'
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item Y';
SELECT pg_sleep(2);
\echo 'B: now wants X (A holds it)'
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item X';
COMMIT;
\echo 'B: finished'
