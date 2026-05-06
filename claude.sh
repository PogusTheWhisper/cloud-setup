#!/usr/bin/env bash
# claude.sh — install Claude Code + useful plugins/skills (macOS + Ubuntu)
# usage: bash claude.sh   |   curl -fsSL <raw>/claude.sh | bash
set -euo pipefail

log()  { printf "\033[1;36m[claude]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }

OS="$(uname -s)"
IS_WIN=0
case "$OS" in MINGW*|MSYS*|CYGWIN*) IS_WIN=1 ;; esac
SUDO=""; [ "$(id -u)" -ne 0 ] 2>/dev/null && SUDO="sudo"
[ "$IS_WIN" = "1" ] && SUDO=""

# ---------- 1. node (need npm) ----------
if ! command -v npm >/dev/null 2>&1; then
  if [ "$IS_WIN" = "1" ]; then
    warn "npm missing. Install Node LTS first:"
    warn "  winget install OpenJS.NodeJS.LTS"
    warn "  then reopen shell and re-run."
    exit 1
  fi
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    log "installing nvm + node LTS"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install --lts >/dev/null
fi

# ---------- 2. claude code CLI ----------
if ! command -v claude >/dev/null 2>&1; then
  log "installing @anthropic-ai/claude-code"
  npm i -g @anthropic-ai/claude-code
else
  log "claude code already installed: $(claude --version 2>/dev/null || echo unknown)"
fi

# ---------- 3. global CLAUDE.md (karpathy skills) ----------
KARPATHY_URL="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"
if [ ! -f "$GLOBAL_CLAUDE" ] || ! grep -q "karpathy" "$GLOBAL_CLAUDE" 2>/dev/null; then
  log "appending karpathy CLAUDE.md to $GLOBAL_CLAUDE"
  {
    [ -f "$GLOBAL_CLAUDE" ] && echo ""
    echo "# karpathy skills"
    curl -fsSL "$KARPATHY_URL"
  } >> "$GLOBAL_CLAUDE"
fi

# ---------- 4. plugin marketplaces ----------
# add via `claude plugin marketplace add <git-or-url>`
# edit/extend this list freely
MARKETS=(
  "obra/superpowers"      # superpowers (TDD, debugging, brainstorming…)
  "anthropics/skills"     # document-skills (xlsx/docx/pptx/pdf)
)
for m in "${MARKETS[@]}"; do
  log "adding marketplace: $m"
  claude plugin marketplace add "$m" </dev/null 2>/dev/null || \
    claude plugin marketplace update "${m##*/}" </dev/null 2>/dev/null || \
    warn "marketplace add failed: $m"
done

# ---------- 5. plugins to auto-install ----------
# marketplace key = repo basename (after slash)
PLUGINS=(
  "superpowers@superpowers"
  "document-skills@skills"
)
for p in "${PLUGINS[@]}"; do
  log "installing plugin: $p"
  claude plugin install "$p" </dev/null || warn "failed: $p"
done

# ---------- 6. caveman (TODO: set source URL) ----------
# CAVEMAN_MARKET=""   # e.g. "user/caveman-plugin"
# [ -n "$CAVEMAN_MARKET" ] && claude plugin marketplace add "$CAVEMAN_MARKET" \
#   && claude plugin install "caveman@$CAVEMAN_MARKET"

# ---------- 7. MCP servers (optional) ----------
# uncomment as needed
# claude mcp add context7 -- npx -y @upstash/context7-mcp
# claude mcp add playwright -- npx -y @playwright/mcp
# claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp

log "done. run: claude"
log "list plugins:  claude plugin list"
log "list skills:   claude skill list"
