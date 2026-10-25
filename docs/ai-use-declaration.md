# AI Use Declaration



1. **AI tool used:** Claude (Anthropic), via Claude Code.
2. **Used for:** case-study selection advice, repository scaffolding, a first draft of the schema and the portfolio plans.
3. **How I reviewed and verified it:** *I ran schema.sql on a real PostgreSQL 16 database in Docker. All 10 tables
were created without errors, and I saved screenshots of the table list and
  the orders table structure as evidence.
- I generated the ER diagram in dbdiagram.io and checked that the tables, keys
  and relationships matched the database.
- I checked the normalisation write-up against my schema, and I can explain
  each functional dependency from the unnormalised sheet through 1NF, 2NF and
  3NF.
- I edited the write-up so the explanations are in my own words, and I
  understand why order\_items stores its own unit\_price and why there is no
  stored order total.
- All SQL for Portfolios 2 to 5 was run and tested by me. I did not submit any*

&#x20; *output that I had not run myself.*



## Technical reflection 

Technical Reflection (Portfolio 1 draft)



Design choices

I chose an online marketplace, ShopCave, because it has enough relationships

to design properly (customers, sellers, products, orders, payments, delivery)

and it gives me real problems to solve later, such as stock being oversold

and slow order queries. I began with one unnormalised order sheet and

normalised it step by step to 3NF, so that each fact is stored in one place.

I kept a unit\_price in order\_items on purpose. It holds the price on the day

of the sale, whereas products.unit\_price holds today's price, so a price

change does not rewrite old orders. I did not store an order total because it

can be calculated, and a stored copy could drift out of step with the items.

I added CHECK constraints (for example stock\_qty >= 0) so that the database

itself rejects bad data, not just the application.



Challenges faced

My first challenge was the environment. Docker Desktop would not start the

engine because the Windows Virtual Machine Platform feature was disabled.

I enabled it in administrator PowerShell, restarted Windows, and updated WSL

before the engine ran. This taught me that a database tool depends on the

operating system layer underneath it. A second challenge was making sure the

schema really worked. Writing it was not enough, so I loaded it into a real

PostgreSQL database and confi-rmed that all 10 tables, keys and constraints

existed.



Lessons learned

Normalisation is about asking what each column depends on, and I now check

whether a column depends on the whole key. I also learned that some

duplication is correct when it records a different fact, as with the price at

the time of sale. Finally, I learned to keep evidence as I go, with

screenshots, scripts and commits, instead of trying to rebuild it at the end.

