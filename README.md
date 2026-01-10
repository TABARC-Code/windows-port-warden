# windows-port-warden

A Windows-first PowerShell toolkit for figuring out who is hogging a port, freeing it, and reserving your usual suspects at logon.

Author: TABARC-Code  
Plugin URI: https://github.com/TABARC-Code/

## What this repo is

Core scripts

- `Who-Owns-Port.ps1`  
  Shows what process is listening on a TCP or UDP port.

- `Free-Port.ps1`  
  Attempts to free a port by stopping the owning process (with a short grace period). Optional `-Force`.

- `Reserve-Ports.ps1`  
  A boring “keep these ports free” runner, designed to be used manually or via Scheduled Task.

Ops

- `Install-PortWardenTask.ps1`  
  Installs or removes a Scheduled Task that runs `Reserve-Ports.ps1` at logon.

Config

- `config.example.json`  
  Defines ports to watch and what to do when they’re in use.

## Requirements

- Windows 10/11
- PowerShell 5.1 or PowerShell 7
- For best results: NetTCPConnection cmdlets available (they usually are)

## Quick start

Find what owns a port:

```powershell
.\Who-Owns-Port.ps1 -Port 8000
```

Free it:

```powershell
.\Free-Port.ps1 -Port 8000
```

If the process is being stubborn:

```powershell
.\Free-Port.ps1 -Port 8000 -Force
```

Reserve a set of ports (from config):

```powershell
.\Reserve-Ports.ps1 -Config .\config.example.json
```

Install Scheduled Task (runs at logon):

```powershell
.\Install-PortWardenTask.ps1 -Install -ConfigPath "C:\Path\To\windows-port-warden\config.json"
```

Remove it:

```powershell
.\Install-PortWardenTask.ps1 -Uninstall
```

## Notes

- This repo does not “reserve” ports at the kernel level. It simply detects conflicts early and clears them if you tell it to.
- If you run it with admin rights, it can see and stop more things. If you run it without admin rights, it will still try, and it will also complain a bit. Fair.

## Licence

MIT.
