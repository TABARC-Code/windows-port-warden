# Config

Copy `config.example.json` to `config.json` and edit it.

## Schema

- `ports`: list of objects
  - `port` (number)
  - `protocol` (`tcp`, `udp`, `both` accepted, case-insensitive)
  - `action` (`warn` or `kill`)
  - `allow` (array of process names to ignore)

- `graceSeconds`: how long to wait before forcing a kill
- `force`: if true, uses `Stop-Process -Force` immediately
- `logPath`: relative path to log file

## Example

```json
{
  "ports": [
    { "port": 8000, "protocol": "tcp", "action": "kill", "allow": ["python"] }
  ],
  "graceSeconds": 3,
  "force": false,
  "logPath": "logs/port-warden.log"
}
```
