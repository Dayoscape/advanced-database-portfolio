# Portfolio 4: NoSQL and Advanced Data Models

## Plan
- **Document (MongoDB):** `products` collection with variable attributes (phone: RAM and storage; shirt: size and colour), with reviews embedded. Explain embed vs reference.
- **Key-value (Redis, optional):** shopping cart and session with TTL.
- Implementation: `mongo-seed.js`, `queries.js` (find, aggregate for average rating per category, index on attributes)
- Suitability argument: why this data does NOT fit rigid columns, and what is given up (joins, transactions, consistency)
- Compare one query in SQL and in Mongo

Evidence: command output screenshots, the sample documents, and the explain output for an indexed query.
