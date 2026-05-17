#!/usr/bin/env bash
# pgclaude.sh — install `pgclaude` shell function (zsh + bash)
# starts `claude` with pre-loaded skills: karpathy-guidelines, using-superpowers, pordee, caveman
# usage: bash pgclaude.sh   |   curl -fsSL <raw>/pgclaude.sh | bash
set -euo pipefail

log()  { printf "\033[1;36m[pgclaude]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }

MARK_BEGIN="# >>> pgclaude >>>"
MARK_END="# <<< pgclaude <<<"

read -r -d '' BLOCK <<'EOF' || true
# >>> pgclaude >>>
# launch claude with pre-loaded skills
pgclaude() {
  local pre="/karpathy-guidelines /using-superpowers /pordee /caveman"
  if [ "$#" -gt 0 ]; then
    command claude "$pre $*"
  else
    command claude "$pre"
  fi
}
# <<< pgclaude <<<
EOF

install_into() {
  local rc="$1"
  [ -e "$rc" ] || touch "$rc"
  if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
    log "already installed in $rc — refreshing block"
    # delete old block, then append fresh
    # portable sed: write to temp
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1; next}
      $0==e {skip=0; next}
      !skip {print}
    ' "$rc" > "$rc.pgtmp" && mv "$rc.pgtmp" "$rc"
  else
    log "installing into $rc"
  fi
  printf "\n%s\n" "$BLOCK" >> "$rc"
}

[ -n "${ZDOTDIR:-}" ] && ZSHRC="$ZDOTDIR/.zshrc" || ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

install_into "$ZSHRC"
install_into "$BASHRC"

log "done. open new shell or: source $ZSHRC"
log "then run: pgclaude"
