# pi-config

Installer that copies `APPEND_SYSTEM.md` and builtin subagent model config into `~/.pi/agent/` for the pi-coding-agent.

## What it does

This repository hosts `APPEND_SYSTEM.md`, a system prompt append file for the pi-coding-agent, and `settings.json`, which pins models for pi's builtin subagents. The `install.sh` script deploys both to `~/.pi/agent/` so they auto-load on startup. A single command is all you need.

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

- **`~/.pi/agent/APPEND_SYSTEM.md`** — System prompt append for the pi-coding-agent
  - On Windows Git Bash this expands to `C:\Users\<you>\.pi\agent\APPEND_SYSTEM.md`.
- **`~/.pi/agent/settings.json`** — Builtin subagent model overrides merged into existing settings
  (non-destructive: only `subagents.agentOverrides` is merged; all other keys are preserved)

- **Pi packages** — The install script also installs these pi packages (best-effort, skipped if `pi` CLI missing or `PI_NO_INSTALL=1`):
  - `git:github.com/obra/superpowers`
  - `npm:context-mode`
  - `npm:pi-mcp-adapter`
  - `npm:pi-web-access`
  - `npm:pi-caveman`
  - `npm:@juicesharp/rpiv-todo`
  - `npm:pi-powerline-footer`
  - `npm:@vndv/pi-codegraph`
  - `npm:pi-subagents`
- The destination directory is created automatically if it does not exist.
- An existing `APPEND_SYSTEM.md` is overwritten on each run; other files are merged non-destructively.

## Uninstall

```bash
rm -f ~/.pi/agent/APPEND_SYSTEM.md
# settings.json subagents block can be removed manually if desired
```

## Files in this repo

| File               | Purpose                                          |
| ------------------ | ------------------------------------------------ |
| `APPEND_SYSTEM.md` | System prompt append for the pi-coding-agent     |
| `settings.json`    | Builtin subagent model config (merged by install.sh) |
| `install.sh`       | Portable installer (Linux & Windows Git Bash)    |
| `README.md`        | This documentation                               |
