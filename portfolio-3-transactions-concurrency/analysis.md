# Portfolio 3: Analysis

## Why transactions matter in ShopCave
Placing an order changes several rows: a new order, its items, the stock level and later a payment. If the process stops halfway, the shop would have a customer charged with no order, or stock reduced with nothing sold. A transaction makes those steps all-or-nothing (atomicity).

## Demo 1 and 2: commit and rollback
In demo 1 the order, the item and the stock reduction commit together (stock went from 10 to 8). In demo 2 the payment fails after the work was done. Inside the transaction the session could see its own order and stock = 8, but after `ROLLBACK` stock was back to 10 and the order did not exist. Other sessions never saw the half-finished order.

## Demo 3: the oversell problem (lost update)
The application reads the stock, takes a moment to decide (3 seconds standing in for a fraud or payment check), then writes the new stock. Both buyers read stock = 1 before either wrote. Both passed the "stock >= 1" check, both inserted an order, and both wrote `stock = 1 - 1 = 0`. The result was **2 orders for 1 unit**, and the final stock of 0 hides the problem because the second write simply overwrote the first. The `CHECK (stock_qty >= 0)` constraint did not catch this, because the code wrote an absolute value (0), not a decrement (stock - 1).

## Demo 4: the fix with row locking
`SELECT ... FOR UPDATE` takes a lock on the product row when it reads it. Buyer B's `SELECT ... FOR UPDATE` had to wait until Buyer A committed, and then read the new value (stock = 0) and was rejected. Only one order existed. The cost is that buyers of the same product are served one at a time, which could be a bottleneck for a very popular item. A cheaper alternative is a single conditional update, `UPDATE products SET stock_qty = stock_qty - 1 WHERE ... AND stock_qty >= 1`, and checking whether a row was updated.

## Demo 5: isolation levels
Under `READ COMMITTED` (the PostgreSQL default), A read the price as 1000 and, in the same transaction, read 1500 after B committed (a non-repeatable read). Under `REPEATABLE READ`, A read 1000 both times, because it kept the snapshot taken at its first query. This works through MVCC: PostgreSQL keeps several versions of a row, so readers do not block writers, and each transaction sees the version that matches its snapshot. The trade-off is that `REPEATABLE READ` can fail with a serialization error when two transactions change the same data, so the application must retry.

## Demo 6: deadlock
A locked X then wanted Y; B locked Y then wanted X. Each waited for the other, which is a deadlock. PostgreSQL detected the cycle after about a second, aborted one transaction with `ERROR: deadlock detected`, and the other completed. That was safe, but one buyer's work failed. The fix is to make every transaction take locks in the same order (here, X before Y); then the second transaction just waits and both succeed.

## Limits of these demos
- Timing is controlled with `pg_sleep`, which makes the races reliable. In production they would be rare and hard to reproduce.
- I used PostgreSQL's default and REPEATABLE READ; I did not demonstrate `SERIALIZABLE`, which could be added.
- The deadlock victim was chosen by PostgreSQL (session B in my run), not by me.

---
*Drafted by Claude from the recorded outputs. Rewrite in your own words and make sure you can explain each demo before submitting.*
