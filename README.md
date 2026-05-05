# cloud-setup

One-shot bootstrap for fresh Ubuntu cloud boxes (and macOS). Installs zsh + oh-my-zsh + plugins, dev tools (git, docker, nvm/node, uv, gcloud, hf-cli, tmux), and writes `~/.zshrc` + `~/.tmux.conf` with credentials baked in via interactive prompts.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/PogusTheWhisper/cloud-setup/main/setup.sh | bash
exec zsh
```

Or local:

```bash
bash setup.sh
```

Prompts for credentials (Kaggle, HF, Typhoon, postgres, ntscraper) — leave blank to skip. Existing `~/.zshrc` / `~/.tmux.conf` are backed up to `.bak.<timestamp>`.

## What it installs

- **Shell**: zsh, oh-my-zsh, theme `robbyrussell`
- **Plugins**: autosuggestions, syntax-highlighting, completions, history-substring-search, autopair, auto-notify, you-should-use, supercharge
- **Tools**: git, docker (Linux), nvm + node LTS, uv, gcloud, huggingface-cli, tmux + TPM
- **tmux**: prefix `Ctrl-a`, vim pane nav, mouse on, plugins (sensible/resurrect/continuum/yank/catppuccin)

## Notes

- Idempotent — safe to re-run
- macOS + Ubuntu auto-detect
- Credentials baked into `~/.zshrc` (chmod 600). **Never commit `~/.zshrc`.**
- Rotate any keys previously leaked.
