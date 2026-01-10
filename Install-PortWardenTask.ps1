# TABARC-Code
# Purpose: Install or remove a Scheduled Task that runs Reserve-Ports.ps1 at logon.
# Notes:
# - Task Scheduler parsing is the kind of petty that makes you miss cron.

[CmdletBinding()]
param(
  [switch]$Install,
  [switch]$Uninstall,
  [string]$TaskName = 'TABARC Port Warden',
  [string]$ConfigPath = '',
  [switch]$RunHighest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail([string]$m) { Write-Error $m; exit 1 }

if (-not $Install -and -not $Uninstall) { Fail "Specify -Install or -Uninstall." }

if ($Uninstall) {
  schtasks /delete /tn $TaskName /f | Out-Null
  Write-Host "Removed task: $TaskName"
  exit 0
}

if (-not $ConfigPath) { Fail "ConfigPath is required for -Install." }
if (-not (Test-Path -LiteralPath $ConfigPath)) { Fail "Config not found: $ConfigPath" }

$runner = Join-Path $PSScriptRoot 'Reserve-Ports.ps1'
if (-not (Test-Path -LiteralPath $runner)) { Fail "Reserve-Ports.ps1 not found next to this installer." }

$ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$args = @(
  '-NoProfile',
  '-ExecutionPolicy', 'Bypass',
  '-File', ('"{0}"' -f $runner),
  '-Config', ('"{0}"' -f $ConfigPath)
)

$tr = '"' + $ps + '" ' + ($args -join ' ')
$rl = if ($RunHighest) { 'highest' } else { 'limited' }

schtasks /create /tn $TaskName /tr $tr /sc onlogon /rl $rl /f | Out-Null
Write-Host "Installed task: $TaskName"
Write-Host "Command: $tr"
