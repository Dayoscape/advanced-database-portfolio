-- Demo 5a: READ COMMITTED (Postgres default). Reads the same price twice; session B changes it in between.
\echo 'A (READ COMMITTED): start'
BEGIN ISOLATION LEVEL READ COMMITTED;
\echo 'A: first read of the price'
SELECT unit_price FROM products WHERE name = 'DEMO Item X';
SELECT pg_sleep(3);
\echo 'A: second read of the price (B has committed a change meanwhile)'
SELECT unit_price FROM products WHERE name = 'DEMO Item X';
COMMIT;
