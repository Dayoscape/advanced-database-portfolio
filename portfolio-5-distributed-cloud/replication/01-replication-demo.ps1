# Replication demo: needs shopcave-pg (primary) and shopcave-pg-replica running.
# Run from anywhere:  .\01-replication-demo.ps1      (output is also saved to ..\outputs\01-replication.txt)
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Docker\Docker\resources\bin" }
$out = Join-Path $PSScriptRoot '..\outputs'; New-Item -ItemType Directory -Force $out | Out-Null
function Pri { docker exec shopcave-pg         psql -U shopcave -d shopcave -c $args[0] 2>&1 | Out-String }
function Rep { docker exec shopcave-pg-replica psql -U shopcave -d shopcave -c $args[0] 2>&1 | Out-String }

$log = @()
$log += "### 1. Primary sees the replica (pg_stat_replication)"
$log += Pri "SELECT application_name, state, sync_state FROM pg_stat_replication;"
$log += "### 2. Is each server a standby? (f = primary, t = replica)"
$log += "primary:"; $log += Pri "SELECT pg_is_in_recovery();"
$log += "replica:"; $log += Rep "SELECT pg_is_in_recovery();"
$log += "### 3. Same data on both (orders count)"
$log += "primary:"; $log += Pri "SELECT count(*) AS orders FROM orders;"
$log += "replica:"; $log += Rep "SELECT count(*) AS orders FROM orders;"
$log += "### 4. Write on the PRIMARY (create table + row), read on the REPLICA"
$log += Pri "DROP TABLE IF EXISTS replication_test; CREATE TABLE replication_test (id serial PRIMARY KEY, note text, at timestamptz DEFAULT now()); INSERT INTO replication_test (note) VALUES ('written on primary');"
Start-Sleep 1
$log += Rep "SELECT id, note FROM replication_test;"
$log += "### 5. Try to write on the REPLICA (must fail: it is read-only)"
$log += Rep "INSERT INTO replication_test (note) VALUES ('written on replica');"
$log += "### 6. Replication lag after a burst of 200,000 rows on the primary"
$log += Pri "INSERT INTO replication_test (note) SELECT 'burst ' || g FROM generate_series(1,200000) g;"
$log += Pri "SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS bytes_behind, replay_lag FROM pg_stat_replication;"
Start-Sleep 2
$log += "replica row count (should equal primary):"
$log += Rep "SELECT count(*) FROM replication_test;"
$log += "primary row count:"
$log += Pri "SELECT count(*) FROM replication_test;"
$log | Tee-Object (Join-Path $out '01-replication.txt')
