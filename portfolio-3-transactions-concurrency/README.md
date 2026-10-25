# Portfolio 3: Transactions and Concurrency

## Plan (each demo = script + terminal output screenshot)
1. **Commit**: place an order (insert order, items, decrement stock) in one transaction
2. **Rollback**: payment fails, so the whole order is rolled back; show stock unchanged
3. **Lost update / oversell**: two sessions buy the last unit with no locking; show the problem
4. **Fix**: `SELECT ... FOR UPDATE`, then compare with `SERIALIZABLE` and its retry on serialization failure
5. **Isolation levels**: demonstrate a non-repeatable read under READ COMMITTED, and its absence under REPEATABLE READ
6. **Deadlock**: two sessions update two products in opposite order; show the Postgres deadlock error and the fix (consistent lock ordering)
7. Short note on MVCC and why readers don't block writers

Files: `01-commit.sql` ... `06-deadlock.sql`, plus `outputs/` for screenshots or logs.
