if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

export PATH="$HOME/GitHub/.devtools/bin:$PATH"

if [ -f "$HOME/.config/terminal/local.zshenv" ]; then
  source "$HOME/.config/terminal/local.zshenv"
fi
