# pi-config

Installer that copies `APPEND_SYSTEM.md` into `~/.pi/agent/` for the pi-coding-agent.

## What it does

This repository hosts `APPEND_SYSTEM.md`, a system prompt append file for the pi-coding-agent. The `install.sh` script deploys it to `~/.pi/agent/` so that the agent auto-loads it on startup. A single command is all you need.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/hyvuonggia/pi-config/master/install.sh | bash
```

Works on Linux and Windows (Git Bash). No `sudo` required.

## Manual install

```bash
git clone https://github.com/hyvuonggia/pi-config.git
cd pi-config
bash install.sh
```

## What gets installed

- **Target path:** `~/.pi/agent/APPEND_SYSTEM.md`
  - On Windows Git Bash this expands to `C:\Users\<you>\.pi\agent\APPEND_SYSTEM.md`.
- The destination directory is created automatically if it does not exist.
- An existing `APPEND_SYSTEM.md` file in that directory is overwritten.

## Uninstall

```bash
rm -f ~/.pi/agent/APPEND_SYSTEM.md
```

## Files in this repo

| File               | Purpose                                          |
| ------------------ | ------------------------------------------------ |
| `APPEND_SYSTEM.md` | System prompt append for the pi-coding-agent     |
| `install.sh`       | Portable installer (Linux & Windows Git Bash)    |
| `README.md`        | This documentation                               |
