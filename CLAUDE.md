# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo shape

Collection of standalone, single-file bootstrap scripts at repo root. No build system, no package manager, no tests. Each script is curl|bash-able and self-contained — **no shared library, no sourcing between scripts**.

| Script | Target |
|--------|--------|
| `env.sh` | macOS + Ubuntu (WSL2 for Windows). Installs zsh + oh-my-zsh + plugins, git, docker, nvm/node, uv, gcloud, gh, hf-cli, tmux + TPM. Prompts for secrets via `/dev/tty` and bakes them into `~/.zshrc` (chmod 600) + `~/.tmux.conf`. |
| `claude.sh` | Linux/macOS/Git Bash. Installs Claude Code CLI + plugins + karpathy `CLAUDE.md`. |
| `claude.ps1` | Native Windows PowerShell equivalent (uses winget). |

## Run / verify

```bash
bash env.sh
bash claude.sh
# windows
irm https://raw.githubusercontent.com/PogusTheWhisper/cloud-setup/main/claude.ps1 | iex
```

No lint/test commands. Verify by running script on fresh VM (or re-running — all scripts idempotent).

## Conventions when editing scripts

- `set -euo pipefail` at top of every bash script.
- Colored `log()` / `warn()` helpers — copy the pattern, don't extract to shared file.
- OS detection via `uname -s`; `MINGW*|MSYS*|CYGWIN*` → Git Bash branch. Native Windows in `env.sh` is rejected with WSL2 hint.
- `SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"` pattern for root-or-not.
- Secrets prompts use `/dev/tty` (with `/dev/stdin` fallback) so `curl|bash` still works interactively. See `ask` / `asksec` in `env.sh`.
- Idempotency is mandatory — guard installs with `command -v X >/dev/null` checks; safe to re-run.
- Adding a script: drop `<name>.sh` in repo root, single-file, no shared lib, add row to README table.

## Critical gotchas

- `env.sh` writes secrets into `~/.zshrc`. Never commit `~/.zshrc`. Rotate leaked keys.
- Claude plugin marketplace IDs are real org/repo paths (e.g. `obra/superpowers`, `anthropics/skills` → `document-skills`); recent commits fixed wrong IDs — verify before changing.
- `env.sh` generates `en_US.UTF-8` locale and exports `LANG`/`LC_ALL` — required for downstream tools.
- zsh plugin name is `vi-mode` (not `vim`) in oh-my-zsh.
- `hf_hub` install bypasses PEP 668 (`pip install --break-system-packages` or pipx) on newer Ubuntu.
