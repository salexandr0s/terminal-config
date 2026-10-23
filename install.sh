#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
TERMINAL_CONFIG_DIR="$HOME/.config/terminal"
GITHUB_ROOT="$HOME/GitHub"

link() {
  local src="$1" dst="$2"
  local backup_dir="" backup_item=""

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok  $dst"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if ! backup_dir=$(mktemp -d "${dst}${BACKUP_SUFFIX}.XXXXXX"); then
      printf '  err could not reserve backup for %s; result: %s\n' "$dst" "${backup_dir:-<empty>}" >&2
      return 1
    fi
    if [ -z "$backup_dir" ]; then
      printf '  err empty backup reservation for %s\n' "$dst" >&2
      return 1
    fi
    case "$backup_dir" in
      "${dst}${BACKUP_SUFFIX}."??????) ;;
      *)
        printf '  err invalid backup reservation for %s: %s\n' "$dst" "${backup_dir:-<empty>}" >&2
        return 1
        ;;
    esac
    if [ "$(dirname "$backup_dir")" != "$(dirname "$dst")" ] ||
       [ ! -d "$backup_dir" ] || [ -L "$backup_dir" ] || [ ! -O "$backup_dir" ] ||
       [ "$(find "$backup_dir" -prune -type d -perm 700 -print)" != "$backup_dir" ]; then
      printf '  err backup reservation is not a private same-parent directory: %s\n' "$backup_dir" >&2
      return 1
    fi
    backup_item="$backup_dir/original"
    if [ -e "$backup_item" ] || [ -L "$backup_item" ] || ! mv "$dst" "$backup_item"; then
      printf '  err could not back up %s; reservation retained at %s\n' "$dst" "$backup_dir" >&2
      return 1
    fi
    printf '  bak %s -> %s\n' "$dst" "$backup_item"
  fi

  if ! mkdir -p "$(dirname "$dst")"; then
    printf '  err could not create parent for %s%s\n' "$dst" "${backup_item:+; recover previous item at $backup_item}" >&2
    return 1
  fi
  if ! ln -s "$src" "$dst"; then
    printf '  err could not link %s%s\n' "$dst" "${backup_item:+; recover previous item at $backup_item}" >&2
    return 1
  fi
  echo "  ln  $dst -> $src"
  return 0
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
  local name="$1"
  local repo="$2"
  local target="$ZSH_CUSTOM_DIR/plugins/$name"

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

ensure_github_root() {
  mkdir -p "$GITHUB_ROOT"
}

echo "Bootstrapping terminal-config..."
echo

ensure_github_root
ensure_brew_bundle
ensure_oh_my_zsh
ensure_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
ensure_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
ensure_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"
ensure_tpm

echo
echo "Linking dotfiles..."
link "$REPO_DIR/zsh/.zshenv" "$HOME/.zshenv"
link "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
link "$REPO_DIR/zsh/.zprofile" "$HOME/.zprofile"
link "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo
ensure_local_examples

echo
echo "Done."
echo "Open a new shell or run: exec zsh"
