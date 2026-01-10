# Idiot’s guide

You’ve got a port. Something is squatting on it. You need it back. Its a simple process and script. nothing fancy. You want fancy prrgram it. Its 3am im tired.

## 1) Who owns port 8000

```powershell
.\Who-Owns-Port.ps1 -Port 8000
```

If it prints a PID and a process name, that’s your culprit.

## 2) Free the port

```powershell
.\Free-Port.ps1 -Port 8000
```

If the process ignores polite requests:

```powershell
.\Free-Port.ps1 -Port 8000 -Force
```

## 3) Keep your usual ports clean

Copy `config.example.json` to `config.json`, edit the ports you care about, then run:

```powershell
.\Reserve-Ports.ps1 -Config .\config.json
```

If you want it to run at logon:

```powershell
.\Install-PortWardenTask.ps1 -Install -ConfigPath "C:\\Path\\To\\windows-port-warden\\config.json"
```

Remove it later:

```powershell
.\Install-PortWardenTask.ps1 -Uninstall
```

## Common failures

- You can’t see the process or can’t kill it: run PowerShell as Administrator.
- The port frees then reappears: something is auto-restarting (services do that). Stop the service, not just the process.
