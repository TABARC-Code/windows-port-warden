# Smoke-test listener discovery and -WhatIf on a local TCP port.
$ErrorActionPreference = 'Stop'
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
try {
  $listener.Start()
  $port = ([Net.IPEndPoint]$listener.LocalEndpoint).Port
  $json = & (Join-Path $PSScriptRoot '..\Who-Owns-Port.ps1') -Port $port -Protocol TCP -ListenOnly -Json
  $owners = @($json | ConvertFrom-Json)
  if (-not @($owners | Where-Object { $_.PID -eq $PID }).Count) {
    throw "Expected the current PowerShell process to own the test listener on $port."
  }
  & (Join-Path $PSScriptRoot '..\Free-Port.ps1') -Port $port -Protocol TCP -WhatIf | Out-Null
  if (-not $listener.Server.IsBound) { throw 'WhatIf unexpectedly stopped the listener.' }
  Write-Host 'Port Warden smoke test passed.'
} finally {
  $listener.Stop()
}
