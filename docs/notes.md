# Notes

This repo doesn’t do kernel-level port reservations. Windows can do that, but it’s messy and depends on services most people don’t want to touch.

Instead, it:
- tells you what owns a port
- optionally kills it
- runs at logon if you want

It is intentionally boring.
