# Cloud deployment of ShopCave (to be done by you)

Goal: run the ShopCave schema on a managed PostgreSQL service and collect screenshots as evidence. This needs your own account, so Claude cannot do it for you.

**Use a NEW, separate project for this course only.** Do not use any work or client project.

## Option A: Neon (neon.tech) or Option B: Supabase (supabase.com)
Both have a free tier. Choose one.

1. Sign up and create a new project named `shopcave-portfolio` (pick the region nearest to you).
2. Copy the **connection string** from the dashboard (Neon: Connect; Supabase: Project Settings, Database, Connection string).
   - The string contains your password. **Never paste it into a file in this repo, into GitHub or into chat.**
3. In PowerShell, store it for this window only (replace the text in quotes with your string):
   ```bash
   $env:CLOUD_DB = "postgresql://..."
   ```
4. Load the schema into the cloud database using the Postgres client that is already inside your local container:
   ```bash
   Get-Content portfolio-1-database-design\schema.sql -Raw | docker exec -i shopcave-pg psql $env:CLOUD_DB
   ```
   (If it complains about the variable, use `docker exec -i -e CLOUD_DB=$env:CLOUD_DB shopcave-pg bash -c 'psql "$CLOUD_DB"'` with the same input.)
5. Check the tables arrived:
   ```bash
   docker exec shopcave-pg psql $env:CLOUD_DB -c "\dt"
   ```
6. Optional: load a small sample of data (do NOT load the 500k rows into a free tier): insert a few customers, products and orders with `INSERT` statements, then run one query.
7. Close the window afterwards, which clears the variable.

## Screenshots to save in `screenshots/` (hide or crop anything with your password or the full connection string)
- [ ] the project dashboard (name, region, PostgreSQL version)
- [ ] `\dt` showing the 10 tables in the cloud database
- [ ] the backup, point-in-time recovery or branching page (what the service offers on the free plan)
- [ ] the settings page showing replicas, high availability or scaling options, or the text that says they are not on the free plan

## Then answer, in your own words, in `analysis.md` section 4
- What did the managed service do for you that you had to do by hand locally (backups, failover, upgrades)?
- What could you not control or configure?
- Where does consistency or availability differ for the cloud version? (For example, does the free tier have a replica?)
- What would it cost to run ShopCave in production on this service? (Read the pricing page and state what you found.)

If you tell Claude which service you used and what the screenshots show, it can help you write section 4. Do not send it your connection string.
