# TABARC-Code
# Purpose: Tell you who owns a port (TCP/UDP).
# Notes:
# - Late night reality: ports are never free, they're just "currently unclaimed".
# - If you run without admin, you might not see everything. Windows enjoys secrets.

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][int]$Port,
  [ValidateSet('TCP','UDP','Both')][string]$Protocol = 'Both',
  [switch]$ListenOnly,
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProcName {
  param([int]$ProcessId)
  try {
    (Get-Process -Id $ProcessId -ErrorAction Stop).ProcessName
  } catch {
    "PID:$ProcessId"
  }
}

function Add-Row {
  param(
    [string]$Proto,
    [string]$Local,
    [string]$Remote,
    [string]$State,
    [int]$ProcessId
  )

  $script:rows += [pscustomobject]@{
    Protocol = $Proto
    Local    = $Local
    Remote   = $Remote
    State    = $State
    PID      = $ProcessId
    Process  = (Get-ProcName -ProcessId $ProcessId)
  }
}

$rows = @()

$wantTcp = $Protocol -in @('TCP','Both')
$wantUdp = $Protocol -in @('UDP','Both')

$usedFallback = $false

if ($wantTcp) {
  try {
    $tcp = Get-NetTCPConnection -LocalPort $Port -ErrorAction Stop
    if ($ListenOnly) { $tcp = $tcp | Where-Object { $_.State -eq 'Listen' } }

    foreach ($c in $tcp) {
      $local  = "{0}:{1}" -f $c.LocalAddress, $c.LocalPort
      $remote = "{0}:{1}" -f $c.RemoteAddress, $c.RemotePort
      Add-Row -Proto 'TCP' -Local $local -Remote $remote -State $c.State -ProcessId $c.OwningProcess
    }
  } catch {
    $usedFallback = $true
  }
}

if ($wantUdp) {
  try {
    $udp = Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Stop
    foreach ($u in $udp) {
      $local = "{0}:{1}" -f $u.LocalAddress, $u.LocalPort
      Add-Row -Proto 'UDP' -Local $local -Remote '' -State 'Listen' -ProcessId $u.OwningProcess
    }
  } catch {
    $usedFallback = $true
  }
}

if ($usedFallback -and $rows.Count -eq 0) {
  # Fallback to netstat. It's ugly, but it exists everywhere.
  try {
    $lines = netstat -ano | Select-String -Pattern "[:.]$Port\s"

    foreach ($m in $lines) {
      $t = ($m.Line -replace '\s+', ' ').Trim().Split(' ')
      if ($t.Length -lt 4) { continue }

      $proto = $t[0].ToUpperInvariant()
      if ($proto -ne 'TCP' -and $proto -ne 'UDP') { continue }

      if ($Protocol -eq 'TCP' -and $proto -ne 'TCP') { continue }
      if ($Protocol -eq 'UDP' -and $proto -ne 'UDP') { continue }

      $local = $t[1]
      $remote = ''
      $state = 'Listen'
      $pid = 0

      if ($proto -eq 'TCP') {
        if ($t.Length -lt 5) { continue }
        $remote = $t[2]
        $state = $t[3]
        $pid = [int]$t[4]
        if ($ListenOnly -and $state -notin @('LISTENING','Listen')) { continue }
      } else {
        # UDP line format is different: Proto Local Foreign PID
        $pid = [int]$t[3]
      }

      Add-Row -Proto $proto -Local $local -Remote $remote -State $state -ProcessId $pid
    }
  } catch {
    # If this fails too, you're in a special kind of Windows day.
  }
}

$rows = $rows | Sort-Object Protocol, Local, PID -Unique

if ($Json) {
  $rows | ConvertTo-Json -Depth 4
} else {
  if ($rows.Count -eq 0) {
    Write-Host "No matches for port $Port ($Protocol)."
  } else {
    $rows | Format-Table -AutoSize
  }
}
