# Portfolio 1: Database Design and Modelling

## To produce (checklist)
- [ ] Case study description (copy from root README, expand)
- [ ] ER diagram (`er-diagram.png`, drawn in draw.io or dbdiagram.io; export source too)
- [ ] Relational schema: `schema.sql` (drafted)
- [ ] Keys and constraints table: why each PK/FK/CHECK/UNIQUE exists
- [ ] Normalisation write-up: start from an unnormalised "order sheet", go 1NF to 2NF to 3NF (`normalisation.md`)
- [ ] Screenshot of schema loaded in psql (`\dt`, `\d orders`)

## Design notes to explain in the write-up
- `order_items.unit_price` stores the price at time of sale, so changing `products.unit_price` later doesn't rewrite history. This is deliberate and not a normalisation violation.
- `order_items` uses a composite PK `(order_id, product_id)`, the resolution of the orders to products many-to-many.
- `categories.parent_id` is a self-reference for a category hierarchy.
- ON DELETE choices: CASCADE for owned children (addresses, order_items), default RESTRICT for financial records.

## Run
```bash
docker compose up -d
docker exec -it shopcave-pg psql -U shopcave -d shopcave -c "\dt"
```
Note: initdb scripts run only on a fresh volume. To reload: `docker compose down -v && docker compose up -d`.
