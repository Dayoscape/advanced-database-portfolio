# Failover demo. It STOPS the primary briefly, promotes the replica, shows it accepting writes,
# restarts the primary, shows the two servers have now diverged, then removes the replica and
# its test table so your main database is back to normal.  Output: ..\outputs\02-failover.txt
# Run from the repository root's compose folder context (it finds the compose files itself).
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Docker\Docker\resources\bin" }
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$out = Join-Path $PSScriptRoot '..\outputs'; New-Item -ItemType Directory -Force $out | Out-Null
function Pri { docker exec shopcave-pg         psql -U shopcave -d shopcave -c $args[0] 2>&1 | Out-String }
function Rep { docker exec shopcave-pg-replica psql -U shopcave -d shopcave -c $args[0] 2>&1 | Out-String }

$log = @()
$log += "### 1. Before: replica is a standby"
$log += Rep "SELECT pg_is_in_recovery();"
$log += "### 2. The PRIMARY crashes (we stop the container)"
$log += (docker stop shopcave-pg 2>&1 | Out-String)
$log += "### 3. Promote the replica to be the new primary"
$log += Rep "SELECT pg_promote();"
Start-Sleep 3
$log += Rep "SELECT pg_is_in_recovery();"
$log += "### 4. The promoted replica now ACCEPTS writes"
$log += Rep "INSERT INTO replication_test (note) VALUES ('written on the promoted replica after failover');"
$log += Rep "SELECT id, note FROM replication_test WHERE note LIKE 'written on%' ORDER BY id;"
$log += "### 5. The old primary comes back. It does NOT have the new row (the servers have diverged: split brain)"
$log += (docker start shopcave-pg 2>&1 | Out-String)
Start-Sleep 6
$log += Pri "SELECT id, note FROM replication_test WHERE note LIKE 'written on%' ORDER BY id;"
$log += "### 6. Clean up: remove test table from the primary and delete the replica"
$log += Pri "DROP TABLE IF EXISTS replication_test;"
Push-Location $root
$log += (docker compose -f docker-compose.yml -f docker-compose.replica.yml rm -sfv postgres-replica 2>&1 | Out-String)
$log += (docker volume rm advanced-database-portfolio_replicadata 2>&1 | Out-String)
Pop-Location
$log += "main database check:"
$log += Pri "SELECT count(*) AS orders FROM orders;"
$log | Tee-Object (Join-Path $out '02-failover.txt')
