-- Demo 5: session B changes the price while A is inside its transaction (starts 1 s after A).
\echo 'B: raising the price by 500 and committing'
UPDATE products SET unit_price = unit_price + 500 WHERE name = 'DEMO Item X';
\echo 'B: done'
