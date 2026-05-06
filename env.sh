#!/usr/bin/env bash
# setup.sh — single-file env bootstrap (macOS + Ubuntu)
# usage: bash setup.sh   |   curl -fsSL <raw>/setup.sh | bash
# prompts for credentials, then writes ~/.zshrc with everything baked in.
set -euo pipefail

log()  { printf "\033[1;36m[setup]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }

OS="$(uname -s)"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

# ---------- prompt for secrets (use /dev/tty so curl|bash works) ----------
TTY=/dev/tty; [ -r "$TTY" ] || TTY=/dev/stdin
ask()    { local p="$1" d="${2:-}" v; printf "\033[1;35m?\033[0m %s%s: " "$p" "${d:+ [$d]}" >/dev/tty 2>/dev/null || printf "? %s: " "$p"; IFS= read -r v <"$TTY" || v=""; printf '%s' "${v:-$d}"; }
asksec() { local p="$1" v; printf "\033[1;35m?\033[0m %s (hidden): " "$p" >/dev/tty 2>/dev/null || printf "? %s: " "$p"; IFS= read -rs v <"$TTY" || v=""; echo >/dev/tty 2>/dev/null || true; printf '%s' "$v"; }

log "credentials — leave blank to skip any field"
KAGGLE_USERNAME_V=$(ask    "KAGGLE_USERNAME")
KAGGLE_KEY_V=$(asksec      "KAGGLE_KEY")
HF_TOKEN_V=$(asksec        "HF_TOKEN")
TYPHOON_API_V=$(asksec     "TYPHOON_API")
PGUSER_V=$(ask             "Postgres user" "postgres")
PGDATABASE_V=$(ask         "Postgres database" "student")

# ---------- 1. system packages ----------
if [ "$OS" = "Linux" ]; then
  log "apt install"
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y
  $SUDO apt-get install -y \
    zsh git curl wget ca-certificates gnupg lsb-release \
    build-essential pkg-config python3 python3-pip python3-venv \
    jq unzip tmux vim htop tree zip postgresql-client default-jre
elif [ "$OS" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    log "installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log "brew install"
  brew install zsh git jq tmux htop tree wget zip postgresql || true
fi

# ---------- 2. uv ----------
command -v uv >/dev/null 2>&1 || { log "uv"; curl -LsSf https://astral.sh/uv/install.sh | sh; }

# ---------- 3. nvm + node ----------
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  log "nvm + node LTS"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  . "$NVM_DIR/nvm.sh" && nvm install --lts
fi

# ---------- 4. docker (Linux) ----------
if [ "$OS" = "Linux" ] && ! command -v docker >/dev/null 2>&1; then
  log "docker"
  curl -fsSL https://get.docker.com | $SUDO sh
  $SUDO usermod -aG docker "$USER" || true
fi

# ---------- 5. gcloud ----------
command -v gcloud >/dev/null 2>&1 || { log "gcloud"; curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$HOME"; }

# ---------- 5b. gh CLI + auth ----------
if ! command -v gh >/dev/null 2>&1; then
  log "installing gh"
  if [ "$OS" = "Linux" ]; then
    $SUDO mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    $SUDO apt-get update -y && $SUDO apt-get install -y gh
  elif [ "$OS" = "Darwin" ]; then
    brew install gh || true
  fi
fi
if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
  log "gh auth login (interactive)"
  gh auth login </dev/tty || warn "gh auth skipped"
fi

# ---------- 6. huggingface-cli ----------
command -v huggingface-cli >/dev/null 2>&1 || pip3 install --user --quiet "huggingface_hub[cli,hf_transfer]" || true

# ---------- 7. oh-my-zsh ----------
export ZSH="$HOME/.oh-my-zsh"
if [ ! -d "$ZSH" ]; then
  log "oh-my-zsh"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ---------- 8. zsh plugins ----------
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
clone_plugin() { local d="$ZSH_CUSTOM/plugins/$1"; [ -d "$d" ] || git clone --depth=1 "$2" "$d"; }
log "zsh plugins"
clone_plugin zsh-autosuggestions          https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting      https://github.com/zsh-users/zsh-syntax-highlighting
clone_plugin zsh-completions              https://github.com/zsh-users/zsh-completions
clone_plugin zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search
clone_plugin zsh-autopair                 https://github.com/hlissner/zsh-autopair
clone_plugin auto-notify                  https://github.com/MichaelAquilina/zsh-auto-notify
clone_plugin you-should-use               https://github.com/MichaelAquilina/zsh-you-should-use
clone_plugin supercharge                  https://github.com/zap-zsh/supercharge

# ---------- 8b. tmux + TPM + config ----------
if ! command -v tmux >/dev/null 2>&1; then
  log "installing tmux"
  if [ "$OS" = "Linux" ]; then $SUDO apt-get install -y tmux
  elif [ "$OS" = "Darwin" ]; then brew install tmux || true
  fi
fi

TPM_DIR="$HOME/.tmux/plugins/tpm"
[ -d "$TPM_DIR" ] || { log "tmux TPM"; git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"; }

log "writing ~/.tmux.conf"
[ -f "$HOME/.tmux.conf" ] && cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$(date +%s)" || true
cat > "$HOME/.tmux.conf" <<'TMUX'
# prefix Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

set -g mouse on
set -g history-limit 100000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g escape-time 10
set -g focus-events on
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# splits keep cwd
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# vim pane nav
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# reload
bind r source-file ~/.tmux.conf \; display "reloaded"

# vi copy mode
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# plugins (prefix + I to install)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'catppuccin/tmux'

set -g @continuum-restore 'on'
set -g @catppuccin_flavour 'mocha'

run '~/.tmux/plugins/tpm/tpm'
TMUX

# ---------- 9. ~/.zshrc (everything baked in) ----------
log "writing ~/.zshrc"
ZSHRC="$HOME/.zshrc"
[ -f "$ZSHRC" ] && cp "$ZSHRC" "$ZSHRC.bak.$(date +%s)" || true

cat > "$ZSHRC" <<ZSHRC_HEAD
# ============= secrets (entered at setup) =============
export KAGGLE_USERNAME='${KAGGLE_USERNAME_V}'
export KAGGLE_KEY='${KAGGLE_KEY_V}'
export HF_TOKEN='${HF_TOKEN_V}'
export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_HOME="\$HOME/hf_cache/"
export TYPHOON_API='${TYPHOON_API_V}'
export PGHOST='localhost'
export PGPORT='5432'
export PGUSER='${PGUSER_V}'
export PGDATABASE='${PGDATABASE_V}'
export PYTORCH_CUDA_ALLOC_CONF='expandable_segments:True'

ZSHRC_HEAD

cat >> "$ZSHRC" <<'ZSHRC_BODY'
# ============= path + oh-my-zsh =============
export PATH="$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(
  git docker docker-compose kubectl history sudo dotenv vim
  emoji encode64 web-search copyfile copypath copybuffer
  dirhistory jsontools
  zsh-autosuggestions zsh-syntax-highlighting zsh-completions
  zsh-history-substring-search zsh-autopair
  auto-notify you-should-use supercharge
)
source $ZSH/oh-my-zsh.sh

# ============= nvm =============
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ============= gcloud =============
[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]       && . "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && . "$HOME/google-cloud-sdk/completion.zsh.inc"

# ============= homebrew (mac) =============
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# ============= aliases =============
alias ll='ls -lah'
alias la='ls -A'
alias cls='clear'
alias gl='git pull'
alias gp='git push'
alias gs='git status'
alias gc='git commit'
alias gco='git checkout'
alias ga='git add'
alias gd='git diff'
alias d='docker'
alias dc='docker compose'
alias k='kubectl'
alias py='python3'
alias t='tmux'
alias ta='tmux attach -t'
alias tls='tmux ls'
alias tn='tmux new -s'
alias tk='tmux kill-session -t'
alias pcpp='find . -type f -exec file {} + | grep "Mach-O 64-bit executable arm64" | cut -d: -f1 | xargs -r rm -f'

# ============= functions =============
unalias dul 2>/dev/null || true
dul() { if du -hd 1 . >/dev/null 2>&1; then du -hd 1 . | sort -hr | head -n 20; else du -h -d 1 . | sort -hr | head -n 20; fi }
czip()  { zip "$@" -x "*.git*" -x "*.git/*" -x "__pycache__/*" -x "*.pyc" -x "*.DS_Store"; }
creq()  { sed 's/[<=>].*//' requirements.txt > requirements_clean.txt; }
pyreq() { pip freeze | grep -v "pkg-resources" > requirements.txt; }
uvv()   { uv init && uv venv --python 3.11 && uv pip install -Uq pip ipykernel ipywidgets; }
uvr()   { uv run "$@"; }
uvre()  { uv pip install -r "$1"; }
uvi()   { uv pip install "$@"; }
uviu()  { uv pip install -qU "$@"; }
uvu()   { uv pip uninstall -yq "$@"; }
pvs()   { cd "$HOME/Documents/Project-VScode/"; }
digital() {
  cd "$HOME/Documents/Project-VScode/Digital" || return
  command -v open >/dev/null && open .
  java -jar Digital.jar
}
hf_model() {
  local MODEL_NAME="$1" FILE_NAME="$2" SUBPATH="$3"
  local TARGET_DIR="${HF_HOME:-$HOME/hf_cache}/$(basename "$MODEL_NAME")"
  [ -n "$SUBPATH" ] && TARGET_DIR="${TARGET_DIR}/${SUBPATH}"
  mkdir -p "$TARGET_DIR"
  if [ -z "$FILE_NAME" ] || [ "$FILE_NAME" = "." ]; then
    huggingface-cli download "$MODEL_NAME" --local-dir "$TARGET_DIR"
  else
    huggingface-cli download "$MODEL_NAME" "$FILE_NAME" --local-dir "$TARGET_DIR"
  fi
}
hf_upmodel() {
  local MODEL_PATH="$1" MODEL_NAME="$2"
  huggingface-cli upload "$(basename "$MODEL_NAME")" "$MODEL_PATH" --repo-type model
}
atg()      { antigravity "$1"; }
gclone()   { git clone "$@"; }
pgclaude() { command claude --dangerously-skip-permissions "$@"; }
psqladd()  { psql -h "$PGHOST" -U "$PGUSER" -p "$PGPORT" -d "$PGDATABASE" -f "$1"; }
init-claude() {
  local URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"
  if [ -f "CLAUDE.md" ]; then echo "" >> CLAUDE.md; curl -fsSL "$URL" >> CLAUDE.md
  else curl -fsSL -o CLAUDE.md "$URL"; fi
}
แสำฟพ() { clear; }
แสห()   { แสำฟพ; }
ZSHRC_BODY

chmod 600 "$ZSHRC"

# ---------- 10. default shell ----------
ZSH_BIN="$(command -v zsh)"
if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
  log "default shell -> zsh"
  $SUDO chsh -s "$ZSH_BIN" "$USER" || warn "chsh failed; run: chsh -s $ZSH_BIN"
fi

log "done. exec zsh"
[ "$OS" = "Linux" ] && log "log out/in for docker group"
warn "~/.zshrc has secrets baked in (chmod 600). do NOT commit it. rotate any previously-leaked keys."
