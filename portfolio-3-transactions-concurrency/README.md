# Portfolio 3: Transactions and Concurrency

All demos use small DEMO rows (products "DEMO Last Unit", "DEMO Item X/Y", buyers `demo-buyer-a/b`) created by `setup.sql`, so the 500k-order dataset is not touched. `setup.sql` resets them before every demo.

## How to run (PowerShell, from this folder)
```bash
.\run-demo.ps1 -Name 03_oversell -A 03_oversell_A.sql -B 03_oversell_B.sql
```
The runner resets the demo data, starts session A, starts session B one second later, prints both outputs and the final state, and saves them in `outputs/`. Single-session demos omit `-B`.
If PowerShell refuses to run the script, run `Set-ExecutionPolicy -Scope Process RemoteSigned` in that window first.

## Demos
| # | Files | What it shows | Result (from `outputs/`) |
|---|---|---|---|
| 1 | `01_commit.sql` | COMMIT: order + item + stock reduction as one unit | stock 10 to 8, order exists |
| 2 | `02_rollback.sql` | ROLLBACK when payment fails | inside the transaction stock is 8 and the order is visible; after ROLLBACK stock is back to 10 and the order is gone |
| 3 | `03_oversell_A/B.sql` | **Problem:** check-then-write with no locking; both buyers read stock = 1 | **2 orders for 1 unit**, stock ends at 0 (oversold; the second write overwrote the first, a lost update) |
| 4 | `04_fixed_A/B.sql` | **Fix:** `SELECT ... FOR UPDATE` | B waits for A, then sees stock = 0 and is rejected; 1 order only |
| 5a | `05_isolation_A_readcommitted.sql` + `05_isolation_B.sql` | READ COMMITTED: non-repeatable read | A reads price 1000, then 1500 inside the same transaction |
| 5b | `05_isolation_A_repeatableread.sql` + `05_isolation_B.sql` | REPEATABLE READ | A reads 1000 both times (keeps its snapshot) even though B committed 1500 |
| 6 | `06_deadlock_A/B.sql` | **Problem:** A locks X then Y, B locks Y then X | PostgreSQL reports `deadlock detected`, aborts B, A completes |
| 6 | `06_deadlock_fixed_A/B.sql` | **Fix:** both lock X then Y | B waits, both commit, no deadlock |

See `analysis.md` for the explanation.
