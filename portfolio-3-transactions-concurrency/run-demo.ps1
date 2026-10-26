# Usage (from this folder):
#   .\run-demo.ps1 -Name 03_oversell -A 03_oversell_A.sql -B 03_oversell_B.sql
# Single-session demo (no B):
#   .\run-demo.ps1 -Name 01_commit -A 01_commit.sql
# Resets demo data, runs session A, starts session B DelayB seconds later, prints both outputs
# and the final state, and saves everything to outputs\<Name>.txt
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$A,
    [string]$B,
    [int]$DelayB = 1
)
$ErrorActionPreference = 'Continue'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Docker\Docker\resources\bin" }
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force outputs | Out-Null

$run = { param($file, $dir) Set-Location $dir; Get-Content $file -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave 2>&1 }

Get-Content setup.sql -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave -q | Out-Null

$jobA = Start-Job $run -ArgumentList $A, $PSScriptRoot
if ($B) { Start-Sleep -Seconds $DelayB; $jobB = Start-Job $run -ArgumentList $B, $PSScriptRoot }

$out = @()
$out += "##### SESSION A ($A)"
$out += Receive-Job $jobA -Wait | Out-String
if ($B) {
    $out += "##### SESSION B ($B, started $DelayB s later)"
    $out += Receive-Job $jobB -Wait | Out-String
}
$out += Get-Content state.sql -Raw | docker exec -i shopcave-pg psql -U shopcave -d shopcave 2>&1 | Out-String
$out | Tee-Object -FilePath "outputs\$Name.txt"
