# MIT 8103 Advanced Database Systems: Individual Portfolio

## Selected case study: ShopCave, an online marketplace

**Nature of the system:** a multi-seller e-commerce marketplace operating in Nigeria. Sellers list products, customers place orders and pay (card, bank transfer, pay-on-delivery), and orders are delivered by region.

**Users of the database:** customers, sellers, delivery agents, platform administrators, analysts.

**Major data stored:** customers and addresses, sellers, categories, products (with varying attributes), stock levels, orders and order items, payments, deliveries, reviews.

**Key operations supported:**
- Browse and search products, place an order, reserve and decrement stock
- Process or fail a payment, with rollback of the order
- Track delivery status
- Seller sales reports and top-product analytics
- Customer order history

## Repository map

| Folder | Portfolio | Marks |
|---|---|---|
| `portfolio-1-database-design/` | Database design and modelling | 7 |
| `portfolio-2-query-optimisation/` | Query processing and optimisation | 7 |
| `portfolio-3-transactions-concurrency/` | Transactions and concurrency | 7 |
| `portfolio-4-nosql/` | NoSQL and advanced data models | 7 |
| `portfolio-5-distributed-cloud/` | Distributed and cloud database | 6 |
| `docs/` | Final documentation, reflection, AI-use declaration | 6 |

## Environment

```bash
docker compose up -d        # PostgreSQL 16 on :5432, MongoDB 7 on :27017
```

Connect: `psql -h localhost -U shopcave -d shopcave` (password in `docker-compose.yml`, local dev only).

## Progress log

| Portfolio | Status |
|---|---|
| 1 | Schema drafted, needs ER diagram and review |
| 2 to 5 | Not started |

## AI-use declaration

See `docs/ai-use-declaration.md`.
