# Portfolio 2: Query Processing and Optimisation

## Plan
1. `seed.sql`: generate ~500k orders and ~1.5M order_items with `generate_series`
2. `queries.sql`: 5 to 6 realistic queries, for example:
   - top 10 products by revenue per month
   - a customer's order history
   - sellers with the lowest delivery success rate
   - products never ordered
3. For each query record: plan BEFORE (`EXPLAIN (ANALYZE, BUFFERS)`), index added, plan AFTER, timings
4. Include one advanced item: partial or covering index, or table partitioning of `orders` by month
5. `analysis.md`: explain why the planner changed (seq scan to index scan, join order, row estimates)

## Evidence to save
- `plans/<query>-before.txt` and `plans/<query>-after.txt`
- A results table with timings
