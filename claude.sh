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
# format: "repo|marketplace-id" (id is from each repo's .claude-plugin/marketplace.json)
MARKETS=(
  "obra/superpowers|superpowers-dev"
  "anthropics/skills|anthropic-agent-skills"
  "kerlos/pordee|pordee"
  "forrestchang/andrej-karpathy-skills|karpathy-skills"
  "affaan-m/everything-claude-code|ecc"
  "JuliusBrussee/caveman|caveman"
  "anthropics/claude-plugins|claude-plugins-official"
  "Dammyjay93/interface-design|interface-design"
)
for entry in "${MARKETS[@]}"; do
  repo="${entry%%|*}"; mid="${entry##*|}"
  log "adding marketplace: $repo (id=$mid)"
  claude plugin marketplace add "$repo" </dev/null 2>/dev/null || \
    claude plugin marketplace update "$mid" </dev/null 2>/dev/null || \
    warn "marketplace add failed: $repo"
done

# ---------- 5. plugins to auto-install ----------
# format: "plugin@marketplace-id"
PLUGINS=(
  "superpowers@superpowers-dev"
  "document-skills@anthropic-agent-skills"
  "pordee@pordee"
  "andrej-karpathy-skills@karpathy-skills"
  "ecc@ecc"
  "caveman@caveman"
  # web-builder essentials (from claude-plugins-official)
  "frontend-design@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "security-guidance@claude-plugins-official"
  "interface-design@interface-design"
)
for p in "${PLUGINS[@]}"; do
  log "installing plugin: $p"
  claude plugin install "$p" </dev/null || warn "failed: $p"
done

# ---------- 6. RTK (token-killer CLI proxy) ----------
if ! command -v rtk >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    log "installing rtk via homebrew"
    brew install rtk
  elif command -v cargo >/dev/null 2>&1; then
    log "installing rtk via cargo"
    cargo install rtk
  else
    warn "rtk: install homebrew or cargo first, then: brew install rtk"
  fi
else
  log "rtk already installed: $(rtk --version 2>/dev/null || echo unknown)"
fi

# ---------- 7. MCP servers ----------
# uncomment as needed
# claude mcp add context7 -- npx -y @upstash/context7-mcp
# claude mcp add playwright -- npx -y @playwright/mcp
log "adding MCP: chrome-devtools"
claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp </dev/null || warn "mcp chrome-devtools failed"
log "adding MCP: desktop-commander"
claude mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander </dev/null || warn "mcp desktop-commander failed"

log "done. run: claude"
log "list plugins:  claude plugin list"
log "list skills:   claude skill list"
