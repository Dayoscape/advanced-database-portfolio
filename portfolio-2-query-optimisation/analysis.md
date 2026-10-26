# Portfolio 2: Performance Analysis

Data: 500k orders, about 1.25M order items, 150k reviews, 20k products (synthetic, see `seed.sql`). I recorded each plan with `EXPLAIN (ANALYZE, BUFFERS)` before and after running `indexes.sql`.

## Where the indexes helped

**Q1, a customer's order history (25.5 ms to 3.4 ms).** Before, the planner scanned the whole `orders` table to find the 3 or so orders of one customer, which is wasteful. After I added an index on `(customer_id, placed_at DESC)`, the planner jumped straight to that customer's rows. The table is small enough that the saving is only milliseconds, but a sequential scan grows with the table while the index lookup barely does, so this matters more as ShopCave grows.

**Q3, stale pending orders (30.3 ms to 0.28 ms).** Only about 5% of orders are pending. A partial index (`WHERE status = 'pending'`) stores only those rows, so it is small, and the query reads it in date order and stops after the first 50. This was the biggest gain, about 100 times faster.

## Where the indexes did not help

**Q2, top products in a month, and Q4, seller failure rate.** Both queries total up a large share of the data. In Q2 the date filter does use the new index on `placed_at`, but the plan still has to read most of `order_items` to join and add up the lines. Q4 touches every delivery and order line. When a query needs a big fraction of a table, reading it in one pass is cheaper than jumping around through an index, so the planner correctly avoided the indexes. The timings also varied a lot between runs (Q2: 207, 273, 840 and 197 ms; Q4: 1497, 1860, 2446 and 1990 ms), so I treat the small differences as noise, not as real slowdowns. To speed these up, another approach would be needed, for example a summary table of revenue per product per month, or partitioning `orders` by month.

**Q5, best rated products.** I created a covering index `(product_id) INCLUDE (rating)` expecting an index-only scan. The planner still chose a sequential scan, both before and after I ran `VACUUM (ANALYZE) reviews`. My first guess was that the table needed vacuuming first, but that did not change the plan. The query has to read every review to compute each product's average, and the whole table is only 150k small rows, so a sequential scan is already cheap (about 12 ms of the 73 ms is the scan itself). So this index is unnecessary for this query at this size.

## What I take from this
- An index helps when a query picks out a small part of a table (Q1, Q3), and does not help when it must process most of it (Q2, Q4, Q5).
- A partial index can be much better than a full index when one value is rare (Q3).
- I should check that the planner actually uses an index, using `EXPLAIN`. Q5 showed an index that existed but was never used, and an unused index still costs space and slows writes.
- A single timing is not reliable, because Q2 varied from 197 to 840 ms with no change to the plan. I should repeat measurements.

## Limitations
- Data is synthetic, so real-world skew may differ.
- Runs were on a laptop under Docker, with other programs running, which adds noise.
- Each result is a handful of runs, not a proper benchmark.

---
*Written from my own benchmark runs. Review it, rewrite it in your own words, and make sure you can explain each plan before submitting.*
