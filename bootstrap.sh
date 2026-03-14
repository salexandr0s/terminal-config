#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a new macOS dev machine from scratch.
# Safe to re-run — skips anything already installed.
#
# Usage:
#   1. Clone the three config repos into ~/GitHub
#   2. Run: ~/GitHub/terminal-config/bootstrap.sh
#
# Repos required:
#   ~/GitHub/terminal-config  — shell, dotfiles, CLI tools
#   ~/GitHub/ai-config        — Claude Code + Codex settings
#   ~/GitHub/ghostty-config   — Ghostty terminal config

GITHUB_ROOT="$HOME/GitHub"
TERMINAL_REPO="$GITHUB_ROOT/terminal-config"
AI_REPO="$GITHUB_ROOT/ai-config"
GHOSTTY_REPO="$GITHUB_ROOT/ghostty-config"

echo "=== Bootstrap ==="
echo ""

# ── 1. Homebrew ──
if command -v brew >/dev/null 2>&1; then
  echo "[ok] Homebrew already installed"
else
  echo "[install] Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── 2. Terminal config (zsh, tmux, CLI tools) ──
if [ -d "$TERMINAL_REPO" ]; then
  echo ""
  echo "=== terminal-config ==="
  "$TERMINAL_REPO/install.sh"
else
  echo "[skip] $TERMINAL_REPO not found — clone it first"
fi

# ── 3. AI config (Claude Code + Codex) ──
if [ -d "$AI_REPO" ]; then
  echo ""
  echo "=== ai-config ==="

  # Claude Code
  if command -v claude >/dev/null 2>&1; then
    echo "[ok] Claude Code already installed"
  else
    echo "[install] Claude Code..."
    npm install -g @anthropic-ai/claude-code
  fi

  # Codex
  if command -v codex >/dev/null 2>&1; then
    echo "[ok] Codex already installed"
  else
    echo "[install] Codex..."
    brew install codex
  fi

  "$AI_REPO/install.sh"
else
  echo "[skip] $AI_REPO not found — clone it first"
fi

# ── 4. Ghostty config ──
if [ -d "$GHOSTTY_REPO" ]; then
  echo ""
  echo "=== ghostty-config ==="
  GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
  mkdir -p "$GHOSTTY_CONFIG_DIR"

  for item in config shaders; do
    src="$GHOSTTY_REPO/$item"
    dst="$GHOSTTY_CONFIG_DIR/$item"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      echo "  [ok] $dst"
    else
      if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "${dst}.bak-$(date +%Y%m%d%H%M%S)"
        echo "  [bak] $dst"
      fi
      ln -s "$src" "$dst"
      echo "  [ln] $dst -> $src"
    fi
  done
else
  echo "[skip] $GHOSTTY_REPO not found — clone it first"
fi

# ── 5. Tailscale ──
if command -v tailscale >/dev/null 2>&1; then
  echo ""
  echo "[ok] Tailscale already installed"
else
  echo ""
  echo "[note] Tailscale not installed — download from https://tailscale.com/download/mac"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Open a new shell: exec zsh"
echo "  2. Set up vault secrets: vault set <key> <value>"
echo "  3. Connect Tailscale: tailscale up"
echo "  4. Tmux plugins: open tmux, press prefix + I"
