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

## Results (fill in after the "after" runs)
| Query | Before (ms) | After (ms) | Plan change | Why |
|---|---|---|---|---|
| Q1 | 25.5 | | | |
| Q2 | 207.0 | | | |
| Q3 | 30.3 | | | |
| Q4 | 1497.0 | | | |
| Q5 | 73.7 | | | |

Write the analysis in `analysis.md` in your own words: what the planner did before, what changed after the index, and whether any index was NOT used or did not help (that is a valid and valuable finding).
