# Scheduled Task notes

The task runs at logon under your user account.

It calls:

`powershell.exe -File Reserve-Ports.ps1 -Config <path>`

If you want it to see and stop processes started by other users or services, you’ll need to run the task with higher privileges.
That’s on purpose. The alternative is “surprise, it killed something important”.

Also, Task Scheduler quoting is… fragile. If your config path has weird characters, simplify it.
