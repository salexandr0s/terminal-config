#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
TERMINAL_CONFIG_DIR="$HOME/.config/terminal"

link() {
  local src="$1" dst="$2"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok  $dst"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "${dst}${BACKUP_SUFFIX}"
    echo "  bak $dst"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  ln  $dst -> $src"
}

ensure_brew_bundle() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Install it first: https://brew.sh"
    exit 1
  fi

  echo "Installing Homebrew packages..."
  brew bundle --file "$REPO_DIR/Brewfile"
}

ensure_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed."
    return
  fi

  echo "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

ensure_plugin() {
  local name="$1" repo="$2" target="$ZSH_CUSTOM_DIR/plugins/$name"

  if [ -d "$target" ]; then
    echo "Plugin already present: $name"
    return
  fi

  git clone "$repo" "$target"
  echo "Installed plugin: $name"
}

ensure_tpm() {
  local target="$HOME/.tmux/plugins/tpm"

  if [ -d "$target" ]; then
    echo "Tmux Plugin Manager already installed."
    return
  fi

  mkdir -p "$(dirname "$target")"
  git clone https://github.com/tmux-plugins/tpm "$target"
  echo "Installed tmux plugin manager."
}

ensure_local_examples() {
  mkdir -p "$TERMINAL_CONFIG_DIR"

  if [ ! -f "$TERMINAL_CONFIG_DIR/local.zsh" ]; then
    cp "$REPO_DIR/zsh/local.example.zsh" "$TERMINAL_CONFIG_DIR/local.zsh"
    echo "Created $TERMINAL_CONFIG_DIR/local.zsh"
  fi

  if [ ! -f "$TERMINAL_CONFIG_DIR/local.zshenv" ]; then
    cp "$REPO_DIR/zsh/local.example.zshenv" "$TERMINAL_CONFIG_DIR/local.zshenv"
    echo "Created $TERMINAL_CONFIG_DIR/local.zshenv"
  fi
}

echo "Bootstrapping terminal-config..."
echo

ensure_brew_bundle
ensure_oh_my_zsh
ensure_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
ensure_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
ensure_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"
ensure_tpm

echo
echo "Linking dotfiles..."
link "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
link "$REPO_DIR/zsh/.zprofile" "$HOME/.zprofile"
link "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo
ensure_local_examples

echo
echo "Done."
echo "Open a new shell or run: exec zsh"
