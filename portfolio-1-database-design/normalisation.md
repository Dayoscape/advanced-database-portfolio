ShopCave: Normalisation and Design Rationale

1. Where I started

I imagined ShopCave running its orders from one big spreadsheet, with one row per order. Everything about the order sat in that one row: who bought, where it goes, what was bought, who sold it, how it was paid, and whether it arrived.

| order_id | order_date | customer_name | customer_email | customer_phone | delivery_address | items | seller_names | payment_method | payment_status | delivery_status |
|---|---|---|---|---|---|---|---|---|---|---|
| 1001 | 2026-09-03 | Ada Obi | ada@mail.com | 0803... | 12 Allen Ave, Ikeja, Lagos | Phone X (1, N250,000); Case (2, N5,000) | TechHub; CaseWorld | card | successful | delivered |

I found four problems with this:
- The `items` and `seller_names` cells hold several values each, so I can't search or total them properly.
- Ada's details are typed again on every order. If her phone number changes, I have to fix it in many rows and could miss one (update anomaly).
- I can't save a customer until they place an order (insert anomaly).
- If I delete Ada's only order, I lose Ada completely (delete anomaly).

2. First Normal Form (1NF)

The rule is that each cell holds one value only, with no lists inside a cell. To fix this, I gave each item in an order its own row. One row now means one product on one order, so the key is *(order_id, product_id)*.

3. Second Normal Form (2NF)

The rule is that, once the key is made of two columns, every other column must depend on both of them and not just one. I checked each column:
- Order date, customer details, address, payment and delivery depend only on `order_id`. That is half the key, so it breaks the rule.
- Product name and seller name depend only on `product_id`. That is also half the key.
- Quantity and price depend on both `order_id` and `product_id`, because they describe that product on that order, so they stay.

So I split the table into *orders*, *products* and *order_items*.

4. Third Normal Form (3NF)

The rule is that a normal column must not depend on another normal column. It should depend on the key only. I looked at what was left and found that some columns were really about a different thing:
- Customer name and phone depend on the customer, not the order, so I made a *customers* table.
- An address is its own thing and can be reused across orders, so I made an *addresses* table.
- A payment can fail and be retried, so it has its own life. I made **payments**, and gave delivery its own table, *deliveries*, for the same reason.
- Seller details depend on the seller, so I made **sellers**. I did the same for *categories*, and added *reviews* for customer feedback.

This gave me the 10 tables in `schema.sql`. Each column now describes only its own table's key.

5. Choices I made on purpose

1. *I store the price again in `order_items`.** It looks like duplication but it isn't, because it is the price on the day of the sale, whereas `products.unit_price` is today's price. If I only kept the current price, changing a price would rewrite old orders.
2. *I don't store the order total.** It can be worked out by adding up quantity times price. Storing it could let it drift out of step with the items. If Portfolio 2 shows it is too slow, I will change this and explain the trade-off.
3. *One delivery per order, but possibly several payments.** `deliveries.order_id` is UNIQUE. `payments.order_id` is not, because a customer might fail to pay and then pay successfully.
4. *One review per customer per product**, enforced by UNIQUE (product_id, customer_id).
5. *I used generated ID numbers as keys.** Emails and names can change, so IDs are safer. Email is still UNIQUE so nobody can register twice.

6. Constraints and why they exist

| Constraint | Where | Purpose |
|---|---|---|
| CHECK (unit_price >= 0) | products, order_items | No negative prices |
| CHECK (stock_qty >= 0) | products | Database-level guard against overselling (central to Portfolio 3) |
| CHECK (quantity > 0) | order_items | No empty or negative lines |
| CHECK (rating BETWEEN 1 AND 5) | reviews | Valid ratings only |
| CHECK status IN (...) | orders, payments, deliveries | Only allowed status values |
| CHECK delivered_at >= dispatched_at | deliveries | A delivery can't arrive before it leaves |
| UNIQUE (email) | customers, sellers | One account per email |
| ON DELETE CASCADE | addresses, order_items, reviews | Child rows are removed with the parent |
| ON DELETE RESTRICT (default) | orders, payments, products | Financial history can't be deleted by accident |

7. Relationships (for the ER diagram)

- Customer 1 to N Address
- Customer 1 to N Order; Order N to 1 Address
- Seller 1 to N Product; Category 1 to N Product; Category 1 to N Category (parent)
- Order M to N Product, resolved by **order_items**
- Order 1 to N Payment; Order 1 to 1 Delivery
- Customer 1 to N Review; Product 1 to N Review
