# TABARC-Code
# Purpose: Keep a list of ports clean (detect conflicts, optionally kill offenders).
# Notes:
# - This isn't kernel reservation. It's "spot the squatter and deal with it".
# - I wrote this after the third coffee and the fifth "Address already in use".

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Config
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Load-Config([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { throw "Config not found: $path" }
  $raw = Get-Content -Raw -LiteralPath $path
  $c = $raw | ConvertFrom-Json
  if (-not $c.ports) { throw "Config missing 'ports' array." }
  $c
}

function Write-Log([string]$msg, [string]$level='INFO') {
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
  $line = "[$ts] [$level] $msg"
  Write-Host $line
  if ($script:LogPath) {
    $dir = Split-Path -Parent $script:LogPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8
  }
}

$c = Load-Config $Config
$script:LogPath = if ($c.logPath) { Join-Path $PSScriptRoot $c.logPath } else { $null }
$grace = if ($c.graceSeconds) { [int]$c.graceSeconds } else { 3 }
$force = if ($null -ne $c.force) { [bool]$c.force } else { $false }

$summary = @()

foreach ($p in $c.ports) {
  $port = [int]$p.port
  $proto = if ($p.protocol) { [string]$p.protocol } else { 'TCP' }
  $action = if ($p.action) { ([string]$p.action).ToLowerInvariant() } else { 'warn' }
  $allow = @()
  if ($p.allow) { $allow = @($p.allow | ForEach-Object { $_.ToString().ToLowerInvariant() }) }

  $ownersJson = & "$PSScriptRoot\Who-Owns-Port.ps1" -Port $port -Protocol $proto -ListenOnly -Json
  $owners = $ownersJson | ConvertFrom-Json
  if (-not $owners) { $owners = @() } elseif ($owners -isnot [System.Array]) { $owners = @($owners) }

  if ($owners.Count -eq 0) {
    Write-Log "Port $port/$proto is free." 'INFO'
    $summary += [pscustomobject]@{port=$port;protocol=$proto;status='free';action=$action;detail=''}
    continue
  }

  $bad = @()
  foreach ($o in $owners) {
    $pn = $(if ($o.Process) { $o.Process } else { 'unknown' }).ToString().ToLowerInvariant()
    if ($allow -contains $pn) {
      Write-Log "Port $port/$proto owned by allowed process: $($o.Process) (PID $($o.PID))" 'INFO'
    } else {
      $bad += $o
    }
  }

  if ($bad.Count -eq 0) {
    $summary += [pscustomobject]@{port=$port;protocol=$proto;status='in-use-allowed';action=$action;detail='allowed'}
    continue
  }

  $detail = ($bad | ForEach-Object { "$($_.Process) PID=$($_.PID)" }) -join ', '
  Write-Log "Port $port/$proto in use: $detail" 'WARN'

  if ($action -eq 'kill') {
    Write-Log "Action=kill. Attempting to free $port/$proto" 'WARN'
    & "$PSScriptRoot\Free-Port.ps1" -Port $port -Protocol $proto -GraceSeconds $grace -Force:$force | Out-Null
    $summary += [pscustomobject]@{port=$port;protocol=$proto;status='attempted-kill';action=$action;detail=$detail}
  } else {
    $summary += [pscustomobject]@{port=$port;protocol=$proto;status='in-use';action=$action;detail=$detail}
  }
}

# Write a quick snapshot for later blame.
$outDir = Join-Path $PSScriptRoot 'out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$out = Join-Path $outDir ("port_warden_{0}.json" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $out -Encoding UTF8
Write-Log "Wrote snapshot: $out" 'INFO'
