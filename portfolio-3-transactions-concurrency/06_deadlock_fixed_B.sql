-- Demo 6 (the FIX): session B also locks X first, then Y, so it simply waits for A. No deadlock.
\echo 'B: locking X then Y (waits for A)'
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item X';
SELECT pg_sleep(2);
UPDATE products SET stock_qty = stock_qty - 1 WHERE name = 'DEMO Item Y';
COMMIT;
\echo 'B: finished'
