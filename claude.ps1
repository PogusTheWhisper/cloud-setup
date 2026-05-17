# claude.ps1 — install Claude Code + plugins on Windows (PowerShell)
# usage: irm https://raw.githubusercontent.com/PogusTheWhisper/cloud-setup/main/claude.ps1 | iex
#    or: powershell -ExecutionPolicy Bypass -File claude.ps1

$ErrorActionPreference = "Stop"
function Log  ($m) { Write-Host "[claude] $m" -ForegroundColor Cyan }
function Warn ($m) { Write-Host "[warn] $m"   -ForegroundColor Yellow }

# ---------- 1. node ----------
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Log "installing Node LTS via winget"
  winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path","User")
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Warn "npm still missing. Reopen PowerShell and re-run."
  exit 1
}

# ---------- 2. claude code CLI ----------
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Log "installing @anthropic-ai/claude-code"
  npm i -g "@anthropic-ai/claude-code"
} else {
  Log "claude already installed"
}

# ---------- 3. global CLAUDE.md (karpathy) ----------
$claudeDir = Join-Path $HOME ".claude"
$claudeMd  = Join-Path $claudeDir "CLAUDE.md"
$karpathy  = "https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
$needAppend = $true
if (Test-Path $claudeMd) {
  if (Select-String -Path $claudeMd -Pattern "karpathy" -Quiet) { $needAppend = $false }
}
if ($needAppend) {
  Log "appending karpathy CLAUDE.md"
  if (Test-Path $claudeMd) { Add-Content $claudeMd "" }
  Add-Content $claudeMd "# karpathy skills"
  (Invoke-WebRequest -UseBasicParsing $karpathy).Content | Add-Content $claudeMd
}

# ---------- 4. marketplaces ----------
$markets = @("obra/superpowers", "anthropics/skills", "kerlos/pordee", "forrestchang/andrej-karpathy-skills", "affaan-m/everything-claude-code", "JuliusBrussee/caveman")
foreach ($m in $markets) {
  Log "adding marketplace: $m"
  try { claude plugin marketplace add $m } catch { Warn "skip: $m" }
}

# ---------- 5. plugins ----------
$plugins = @(
  "superpowers@superpowers",
  "document-skills@skills",
  "pordee@pordee",
  "andrej-karpathy-skills@karpathy-skills",
  "ecc@ecc",
  "caveman@caveman"
)
foreach ($p in $plugins) {
  Log "installing plugin: $p"
  try { claude plugin install $p } catch { Warn "skip: $p" }
}

# ---------- 6. MCP (TODO: uncomment) ----------
# claude mcp add context7 -- npx -y "@upstash/context7-mcp"
# claude mcp add playwright -- npx -y "@playwright/mcp"

Log "done. run: claude"
