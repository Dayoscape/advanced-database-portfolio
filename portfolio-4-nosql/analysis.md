# Portfolio 4: Analysis

## Why a document database suits part of ShopCave
Products in ShopCave do not share the same attributes. A phone has RAM, storage and battery; a shirt has size, colour and material. In the relational schema from Portfolio 1 there are only two ways to hold this, and both have a cost:
- **One wide `products` table** with a column for every attribute of every category. Most values would be NULL (a shirt has no RAM), and each new category needs a schema change.
- **An entity-attribute-value table** (`product_id, attribute_name, attribute_value`). It is flexible, but one product is spread over many rows, values are all strings, and a query like "phones with 8+ GB RAM under N300,000" needs a self-join for each attribute.

A document can simply hold the attributes that apply to that product, so the phone query reads a single document per product and needs no joins. The same collection can hold new categories without changing a schema.

## Embed or reference
| Data | Choice | Reason |
|---|---|---|
| Order items, shipping address and payment inside the order | **Embedded** | They are always read with the order, are only changed together with it, and an order history is one read (Q6) with no join |
| Latest 3 reviews and `reviewStats` inside the product | **Embedded** | Shown on the product page with the product, and the average can be read without counting reviews |
| Seller in the product | **Reference** (`sellerId`) | A seller has many products and its details change; copying them would create inconsistent duplicates |
| Product name and price inside the order items | **Copied** | An order must show what was bought at that time, so this is a deliberate snapshot |

## What I give up compared with PostgreSQL
- **Duplication and consistency:** if a product is renamed, old orders keep the old name (intended here), but `reviewStats` must be kept in step with the reviews by the application. PostgreSQL's constraints and foreign keys would enforce this for me.
- **No enforced schema by default:** a typo such as `ram_gbb` would be stored silently. MongoDB can validate documents with a JSON Schema, which I did not set up.
- **Joins and cross-collection reports are harder.** Q7 (top products by revenue) works by unwinding the items inside orders, which is fine here but gets awkward when I need to join in seller or category data.
- **Multi-document transactions** exist in MongoDB but are heavier. This is why stock and payments, where Portfolio 3 showed locking matters, should stay in PostgreSQL.

My conclusion is a hybrid design: PostgreSQL for orders, stock and payments (strong consistency), MongoDB for the catalogue and for order history reads (flexible shape, fast reads).

## Index experiment (100k products and 100k orders)
I ran the experiment twice. The second run is in `screenshots/04-index-explain.png`.

| Query | Run 1: before to after | Run 2: before to after | Examined |
|---|---|---|---|
| Q1 phones, RAM >= 8, price < 300k, sorted by price | 122 ms to 61 ms | 1585 ms to 185 ms | 100,000 to 5,966 |
| Q2 black size-M shirts | 52 ms to 2 ms | 81 ms to 4 ms | 100,000 to 1,207 |
| Q3 products tagged "bestseller" | 48 ms to 33 ms | 68 ms to 51 ms | 100,000 to 26,741 |
| Q6 one customer's order history | 93 ms to 1 ms | 997 ms to 1 ms | 100,000 to 2 |

The plan (COLLSCAN before, IXSCAN after) and the number of documents examined were the same in both runs, but the timings differed a lot (the Q1 full scan took 122 ms in run 1 and 1585 ms in run 2, probably because of cold caches or other programs running). So the **documents examined** is the reliable measure, and the milliseconds are only indicative.

- **Q6 and Q2 gained the most** because they return a tiny share of the collection, so the index lets MongoDB skip almost everything.
- **Q3 barely improved.** About 27% of products carry the tag, so the index still has to visit more than a quarter of the documents. This is the same lesson as in Portfolio 2: an index helps most when the query is selective.
- **Q1 improved 2x in run 1 and about 8x in run 2**, so the size of the gain is uncertain, but it was an improvement both times. It is less dramatic than Q6 because it still returns almost 6,000 documents. The compound index follows the order equality, then range, then sort (`category`, `attributes.ram_gb`, `price`). That order can still make MongoDB sort in memory because `ram_gb` is a range, which is a possible further improvement I did not test.
- These are single runs on a laptop in Docker, so small differences (such as Q3) are within noise.

## Limits
- Data is synthetic, and the 100k size is small compared with a real marketplace.
- Only the document model is implemented. I considered a Redis key-value store for carts and sessions (fast, expires with a time limit) but did not build it.
- I did not set up a JSON Schema validator or measure write performance.

---
*Drafted by Claude from the recorded outputs. Rewrite in your own words and make sure you can explain the model and each result before submitting.*
