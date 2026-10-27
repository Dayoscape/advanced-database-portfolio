# Portfolio 4: NoSQL and Advanced Data Models (MongoDB, document model)

Same case study (ShopCave). Same ids as PostgreSQL: `products._id` = `products.product_id`, `orders._id` = `orders.order_id`.

## Model
**`products` collection (one document per product)**
```json
{ "_id": 4, "sellerId": 472, "name": "Phone 4", "category": "Phones", "price": 215853, "stock": 472,
  "attributes": { "brand": "Tecno", "ram_gb": 2, "storage_gb": 32, "battery_mah": 4081, "dual_sim": true },
  "tags": ["local", "gift"],
  "reviews": [ { "customerId": 17, "rating": 4, "comment": "Works well", "at": "..." } ],
  "reviewStats": { "count": 1, "avg": 4 } }
```
Shirts carry `size, colour, material, fit`; shoes carry `size_eu, type, waterproof`; laptops carry `cpu, ssd_gb, screen_inch`. Each category has different attributes.

**`orders` collection (one document per order, with items, address and payment embedded)**
```json
{ "_id": 1, "customerId": 123, "status": "paid", "placedAt": "...",
  "shippingAddress": { "street": "...", "city": "...", "state": "Lagos" },
  "items": [ { "productId": 77, "name": "Product 77", "qty": 2, "unitPrice": 15000 } ],
  "payment": { "method": "card", "amount": 30000, "status": "successful" } }
```
Item name and price are copied at the time of sale (a snapshot, like `order_items.unit_price` in SQL).

## Files
| File | Purpose |
|---|---|
| `seed.js` | creates 100k products and 100k orders (seeded random, repeatable) |
| `queries.js` | 7 example queries: attribute filters, array filter, aggregations, single-read order history |
| `explain_indexes.js` | before/after `explain("executionStats")` with indexes |
| `outputs/` | saved output of each run |
| `analysis.md` | suitability, trade-offs, results, comparison with SQL |

## How to run (PowerShell, from this folder)
```bash
docker cp seed.js shopcave-mongo:/tmp/seed.js
docker exec shopcave-mongo mongosh --quiet shopcave /tmp/seed.js
```
Do the same for `queries.js` and `explain_indexes.js`.

## Results (index experiment, 100k products / 100k orders)
| Query | Run 1 before to after | Run 2 before to after (`screenshots/04-index-explain.png`) | Examined (before to after) |
|---|---|---|---|
| Q1 phones RAM >= 8, price < 300k, sorted | 122 ms to 61 ms | 1585 ms to 185 ms | 100,000 to 5,966 |
| Q2 black size-M shirts | 52 ms to 2 ms | 81 ms to 4 ms | 100,000 to 1,207 |
| Q3 tag "bestseller" | 48 ms to 33 ms | 68 ms to 51 ms | 100,000 to 26,741 |
| Q6 one customer's orders | 93 ms to 1 ms | 997 ms to 1 ms | 100,000 to 2 |

Two separate runs on the same data. The plans and the number of documents examined are identical in both runs, but the milliseconds differ a lot (for example the Q1 "before" took 122 ms in run 1 and 1585 ms in run 2), so timings on this laptop are noisy. See `analysis.md`.
