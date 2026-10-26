# Portfolio 2: Query Processing and Optimisation

## Data
`seed.sql` generates synthetic ShopCave data: 50k customers, 500 sellers, 20k products, 500k orders, about 1.25M order items, 500k payments, 400k deliveries, 150k reviews. It uses `setseed()` so the data is repeatable. Popular products are picked more often (skewed random), as in a real shop.

## Queries
| File | What it asks | Idea to test |
|---|---|---|
| `q1_customer_history.sql` | one customer's orders and totals | composite index (customer_id, placed_at) |
| `q2_top_products_month.sql` | top 10 products by revenue for one month | index on date range, index on order_items(product_id) |
| `q3_stale_pending.sql` | pending orders older than 7 days | partial index (about 5% of rows) |
| `q4_seller_delivery_failures.sql` | sellers with most failed deliveries | join order, index on order_items(product_id) |
| `q5_best_rated_products.sql` | best rated products with 20+ reviews | covering index (INCLUDE) |

## How to run (PowerShell, from this folder)
```bash
Get-Content seed.sql -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave
```
Run one query and save its plan:
```bash
Get-Content queries\q1_customer_history.sql -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave
```
1. Plans before indexes are in `plans/qN-before.txt`.
2. Run `indexes.sql`, then run each query again and save the plans as `plans/qN-after.txt`.

## Results
Single runs of `EXPLAIN (ANALYZE, BUFFERS)` on the same machine. Q2 and Q4 vary a lot between runs (see `analysis.md`).

| Query | Before (ms) | After (ms) | Plan change | Verdict |
|---|---|---|---|---|
| Q1 | 25.5 | 3.4 | Parallel Seq Scan on orders → Bitmap Index Scan on `idx_orders_customer_placed` | Faster (about 7x) |
| Q2 | 207.0 | 273 (reruns: 840, 197) | Seq Scan on orders → Bitmap Index Scan on `idx_orders_placed_at`; order_items still scanned fully | No real change |
| Q3 | 30.3 | 0.28 | Parallel Seq Scan → Index Scan on partial index `idx_orders_pending` | Faster (about 100x) |
| Q4 | 1497.0 | 1860 (reruns: 2446, 1990) | No index used; every big table still scanned | No gain, slightly worse |
| Q5 | 73.7 | 87.7 (after VACUUM: 73.4) | `idx_reviews_product_rating` never used; Seq Scan on reviews | No gain |

Plans: `plans/qN-before.txt`, `plans/qN-after.txt`, `plans/q5-after-vacuum.txt`. Analysis: `analysis.md`.
