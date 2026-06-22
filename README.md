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

- **`~/.pi/agent/APPEND_SYSTEM.md`** — System prompt append for the pi-coding-agent
  - On Windows Git Bash this expands to `C:\Users\<you>\.pi\agent\APPEND_SYSTEM.md`.
- **`~/.pi/agent/agents/*.md`** — 7 custom subagent definitions:

| Subagent | Role |
| --- | --- |
| council | Multi-LLM consensus and synthesis for high-stakes tradeoffs and architectural decisions |
| designer | UI/UX implementation and visual excellence for interfaces, components, and design systems |
| explorer | Fast codebase reconnaissance to map unknown areas and build context for other agents |
| fixer | Fast, scoped implementation specialist that turns approved specs into working code |
| librarian | External knowledge retrieval and synthesis from documentation, specs, and ecosystem |
| observer | Passive monitoring and validation of ongoing work against specs and expectations |
| oracle | Strategic advisor and debugger of last resort for architectural decisions and hard bugs |

- **`~/.pi/agent/settings.json`** — Subagent model config merged into existing settings
  (non-destructive: only `subagents.agentOverrides` is merged; all other keys are preserved)
- **Pi packages** — The install script also installs these pi packages (best-effort, skipped if `pi` CLI missing or `PI_NO_INSTALL=1`):
  - `git:github.com/obra/superpowers`
  - `npm:context-mode`
  - `npm:pi-mcp-adapter`
  - `npm:pi-web-access`
  - `npm:pi-caveman`
  - `npm:@juicesharp/rpiv-todo`
- The destination directory is created automatically if it does not exist.
- An existing `APPEND_SYSTEM.md` and subagent files are overwritten on each run.

## Uninstall

```bash
rm -f ~/.pi/agent/APPEND_SYSTEM.md
rm -rf ~/.pi/agent/agents
```

## Files in this repo

| File               | Purpose                                          |
| ------------------ | ------------------------------------------------ |
| `APPEND_SYSTEM.md` | System prompt append for the pi-coding-agent     |
| `agents/*.md`      | 7 custom subagent definitions (council, etc.)    |
| `settings.json`    | Subagent model config (merged by install.sh)     |
| `install.sh`       | Portable installer (Linux & Windows Git Bash)    |
| `README.md`        | This documentation                               |
