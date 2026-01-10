# Config notes

`config.json` is intentionally plain.

- `ports[]`
  - `port`: number
  - `protocol`: `tcp`, `udp`, or `both`
  - `action`: `warn` or `kill`
  - `allow`: list of process names that are allowed to own the port (case-insensitive, no `.exe` needed)

- `graceSeconds`: how long we wait before re-checking a port after asking a process to stop
- `force`: whether we use `Stop-Process -Force` when killing
- `logPath`: where logs go (created if missing)

Yes, it’s crude. That’s the point.
