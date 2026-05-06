# cloud-setup

Collection of single-file bootstrap scripts. Each is standalone and curl|bash-able.

## Scripts

| Script | Purpose |
|--------|---------|
| [`env.sh`](env.sh) | Cloud zsh env: zsh + oh-my-zsh + plugins, git, docker, nvm/node, uv, gcloud, gh, hf-cli, tmux + TPM, writes `~/.zshrc` + `~/.tmux.conf` (prompts for secrets). |
| [`claude.sh`](claude.sh) | Claude Code CLI + plugins (superpowers, hookify, pr-review-toolkit, frontend-design) + global karpathy `CLAUDE.md`. Edit script to add caveman / MCP servers. |

## Usage

Run any script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/PogusTheWhisper/cloud-setup/main/env.sh | bash
curl -fsSL https://raw.githubusercontent.com/PogusTheWhisper/cloud-setup/main/claude.sh | bash
```

Or local:

```bash
bash env.sh
bash claude.sh
```

All scripts idempotent — safe to re-run. macOS + Ubuntu auto-detect.

## Adding a script

1. Drop `<name>.sh` in repo root
2. Single-file, standalone, no shared lib
3. `set -euo pipefail` + colored `log`/`warn`
4. Add row to table above

## Notes

- `env.sh` bakes secrets into `~/.zshrc` (chmod 600). Never commit `~/.zshrc`.
- Rotate any leaked keys.
