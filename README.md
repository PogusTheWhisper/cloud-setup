# cloud-setup

Collection of single-file bootstrap scripts. Each is standalone and curl|bash-able.

## Scripts

| Script | Purpose |
|--------|---------|
| [`env.sh`](env.sh) | Cloud zsh env: zsh + oh-my-zsh + plugins, git, docker, nvm/node, uv, gcloud, gh, hf-cli, tmux + TPM, writes `~/.zshrc` + `~/.tmux.conf` (prompts for secrets). |
| [`claude.sh`](claude.sh) | Claude Code CLI + plugins + karpathy `CLAUDE.md` (Linux/macOS/Git Bash). |
| [`claude.ps1`](claude.ps1) | Same as `claude.sh` for native Windows PowerShell (uses winget). |
| [`pgclaude.sh`](pgclaude.sh) | Install `pgclaude` shell function — launches `claude` pre-loaded with `/karpathy-guidelines /using-superpowers /pordee /caveman`. |

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

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/PogusTheWhisper/cloud-setup/main/claude.ps1 | iex
```

All scripts idempotent — safe to re-run. macOS + Linux auto-detect. Native Windows: use `claude.ps1`; for `env.sh` use WSL2 (`wsl --install -d Ubuntu`).

## Adding a script

1. Drop `<name>.sh` in repo root
2. Single-file, standalone, no shared lib
3. `set -euo pipefail` + colored `log`/`warn`
4. Add row to table above

## Notes

- `env.sh` bakes secrets into `~/.zshrc` (chmod 600). Never commit `~/.zshrc`.
- Rotate any leaked keys.
