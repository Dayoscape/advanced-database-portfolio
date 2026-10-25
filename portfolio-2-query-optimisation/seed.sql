-- ShopCave synthetic data for Portfolio 2 (all data is fake, generated with generate_series)
-- Target sizes: 50k customers, 500 sellers, 20k products, 500k orders, ~1.25M order_items.
-- Re-runnable: it empties the tables first.

SELECT setseed(0.42);   -- makes the random data repeatable

TRUNCATE reviews, deliveries, payments, order_items, orders, products,
         categories, sellers, addresses, customers RESTART IDENTITY CASCADE;

-- 20 top-level categories
INSERT INTO categories (name)
SELECT 'Category ' || g FROM generate_series(1, 20) g;

-- 500 sellers spread over 10 states
INSERT INTO sellers (business_name, email, state, joined_at)
SELECT 'Seller ' || g,
       'seller' || g || '@example.test',
       (ARRAY['Lagos','Abuja','Rivers','Kano','Oyo','Enugu','Kaduna','Delta','Ogun','Anambra'])[1 + (g % 10)],
       now() - random() * interval '1000 days'
FROM generate_series(1, 500) g;

-- 50k customers, one default address each (so address_id = customer_id)
INSERT INTO customers (full_name, email, phone, created_at)
SELECT 'Customer ' || g,
       'customer' || g || '@example.test',
       '080' || lpad((g % 100000000)::text, 8, '0'),
       now() - random() * interval '900 days'
FROM generate_series(1, 50000) g;

INSERT INTO addresses (customer_id, street, city, state, is_default)
SELECT g, g || ' Test Street',
       'City ' || (g % 50),
       (ARRAY['Lagos','Abuja','Rivers','Kano','Oyo','Enugu','Kaduna','Delta','Ogun','Anambra'])[1 + (g % 10)],
       true
FROM generate_series(1, 50000) g;

-- 20k products
INSERT INTO products (seller_id, category_id, name, description, unit_price, stock_qty)
SELECT 1 + floor(random() * 500)::int,
       1 + floor(random() * 20)::int,
       'Product ' || g,
       'Synthetic product ' || g,
       round((500 + random() * 499500)::numeric, 2),
       floor(random() * 500)::int
FROM generate_series(1, 20000) g;

-- 500k orders over the last two years
INSERT INTO orders (customer_id, address_id, status, placed_at)
SELECT c, c,
       CASE WHEN r < 0.05 THEN 'pending'
            WHEN r < 0.10 THEN 'cancelled'
            WHEN r < 0.20 THEN 'paid'
            WHEN r < 0.30 THEN 'shipped'
            ELSE 'delivered' END,
       now() - random() * interval '730 days'
FROM (SELECT (1 + floor(random() * 50000))::int AS c, random() AS r
      FROM generate_series(1, 500000)) s;

-- 1 to 4 items per order; popular products are picked more often (power(random(), 2.5) skews low ids)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT DISTINCT ON (t.order_id, t.pid)
       t.order_id, t.pid, (1 + floor(random() * 3))::int, p.unit_price
FROM (SELECT o.order_id,
             (1 + floor(power(random(), 2.5) * 20000))::int AS pid
      FROM orders o
      CROSS JOIN generate_series(1, 4) k
      WHERE k <= 1 + (o.order_id % 4)) t
JOIN products p ON p.product_id = t.pid;

-- one payment per order
INSERT INTO payments (order_id, method, amount, status, paid_at)
SELECT o.order_id,
       (ARRAY['card','transfer','cod'])[1 + floor(random() * 3)::int],
       s.total,
       CASE WHEN o.status IN ('paid','shipped','delivered') THEN 'successful'
            WHEN o.status = 'cancelled' THEN 'failed'
            ELSE 'initiated' END,
       CASE WHEN o.status IN ('paid','shipped','delivered') THEN o.placed_at + interval '5 minutes' END
FROM orders o
JOIN (SELECT order_id, SUM(quantity * unit_price) AS total
      FROM order_items GROUP BY order_id) s USING (order_id);

-- deliveries for shipped and delivered orders (about 5% of delivered ones fail)
INSERT INTO deliveries (order_id, status, dispatched_at, delivered_at)
SELECT order_id,
       CASE WHEN status = 'shipped' THEN 'in_transit'
            WHEN r < 0.05 THEN 'failed'
            ELSE 'delivered' END,
       placed_at + interval '1 day',
       CASE WHEN status = 'delivered' AND r >= 0.05
            THEN placed_at + interval '1 day' + random() * interval '6 days' END
FROM (SELECT order_id, status, placed_at, random() AS r
      FROM orders WHERE status IN ('shipped','delivered')) s;

-- about 150k review attempts (duplicates are skipped by the UNIQUE constraint)
INSERT INTO reviews (product_id, customer_id, rating, comment, created_at)
SELECT (1 + floor(power(random(), 2.5) * 20000))::int,
       (1 + floor(random() * 50000))::int,
       (1 + floor(random() * 5))::int,
       'Synthetic review',
       now() - random() * interval '700 days'
FROM generate_series(1, 150000)
ON CONFLICT DO NOTHING;

ANALYZE;   -- refresh planner statistics

SELECT 'customers' AS tbl, count(*) FROM customers UNION ALL
SELECT 'products', count(*) FROM products UNION ALL
SELECT 'orders', count(*) FROM orders UNION ALL
SELECT 'order_items', count(*) FROM order_items UNION ALL
SELECT 'payments', count(*) FROM payments UNION ALL
SELECT 'deliveries', count(*) FROM deliveries UNION ALL
SELECT 'reviews', count(*) FROM reviews;
