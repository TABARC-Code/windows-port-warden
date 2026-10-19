# TABARC-Code
# Purpose: Free a TCP/UDP port by stopping the owning process.
# Notes:
# - This can kill your own dev server. That's the point. Don't be precious.
# - If you kill the wrong thing at 2am, that's between you and your conscience.

[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [Parameter(Mandatory=$true)][int]$Port,
  [ValidateSet('TCP','UDP','Both')][string]$Protocol = 'Both',
  [int]$GraceSeconds = 3,
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Owners {
  $json = & "$PSScriptRoot\Who-Owns-Port.ps1" -Port $Port -Protocol $Protocol -Json
  $rows = $json | ConvertFrom-Json
  if (-not $rows) { return @() }
  if ($rows -is [System.Array]) { return $rows }
  return @($rows)
}

$owners = Get-Owners
if ($owners.Count -eq 0) {
  Write-Host "Port $Port looks free already. Fine."
  exit 0
}

$uniquePids = $owners | Select-Object -ExpandProperty PID -Unique
foreach ($processId in $uniquePids) {
  $p = Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue
  $name = if ($p) { $p.ProcessName } else { 'Unknown' }

  if (-not $p) {
    Write-Host "PID $processId vanished. Good riddance."
    continue
  }

  $msg = "Stopping $name (PID $processId) to free port $Port"
  if ($PSCmdlet.ShouldProcess($msg)) {
    try {
      # First try a polite stop.
      Stop-Process -Id $p.Id -ErrorAction SilentlyContinue
      Start-Sleep -Seconds $GraceSeconds

      $still = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
      if ($still) {
        if ($Force) {
          Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
          Write-Host "Forced stop: $name (PID $processId)"
        } else {
          Write-Host "Still running after $GraceSeconds s: $name (PID $processId). Use -Force if you mean it."
        }
      } else {
        Write-Host "Stopped: $name (PID $processId)"
      }
    } catch {
      Write-Error "Failed to stop PID $processId: $($_.Exception.Message)"
    }
  }
}

# Final check
$after = Get-Owners
if ($after.Count -eq 0) {
  Write-Host "Port $Port now appears free."
} else {
  Write-Host "Port $Port still has owners. Something's respawning or you're missing permissions."
  $after | Format-Table -AutoSize
}
