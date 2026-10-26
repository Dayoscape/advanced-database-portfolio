-- Demo 5b: REPEATABLE READ. Same reads as 5a; the transaction keeps its original snapshot.
\echo 'A (REPEATABLE READ): start'
BEGIN ISOLATION LEVEL REPEATABLE READ;
\echo 'A: first read of the price'
SELECT unit_price FROM products WHERE name = 'DEMO Item X';
SELECT pg_sleep(3);
\echo 'A: second read of the price (B has committed a change meanwhile)'
SELECT unit_price FROM products WHERE name = 'DEMO Item X';
COMMIT;
