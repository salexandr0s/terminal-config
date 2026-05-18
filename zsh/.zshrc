export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  fzf-tab
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Completion UX closer to fish.
setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' special-dirs true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --all --color=always --group-directories-first $realpath'

# Homebrew and user paths.
case ":$PATH:" in
  *":/opt/homebrew/bin:"*) ;;
  *) export PATH="/opt/homebrew/bin:$PATH" ;;
esac

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export GITHUB_ROOT="${GITHUB_ROOT:-$HOME/GitHub}"
export TERMINAL_CONFIG_REPO="${TERMINAL_CONFIG_REPO:-$GITHUB_ROOT/terminal-config}"

if [ -d "$TERMINAL_CONFIG_REPO/bin" ]; then
  case ":$PATH:" in
    *":$TERMINAL_CONFIG_REPO/bin:"*) ;;
    *) export PATH="$TERMINAL_CONFIG_REPO/bin:$PATH" ;;
  esac
fi

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

if [[ -z "$OPENCLAW_BIN" && -x "$HOME/Library/pnpm/openclaw" ]]; then
  export OPENCLAW_BIN="$HOME/Library/pnpm/openclaw"
fi

if [ -s "$HOME/.openclaw/completions/openclaw.zsh" ]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi

if [ -s "$HOME/.bun/_bun" ]; then
  source "$HOME/.bun/_bun"
fi

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if [[ "${TERM:-}" != "dumb" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if [[ -o interactive && -t 0 ]]; then
  if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
  fi

  if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
  fi
fi

alias cat="bat"
alias ls="eza --icons"
alias ll="eza --icons -la --git"
alias lt="eza --icons --tree --level=2"
alias lg="lazygit"
alias y="yazi"

cdgh() { cd "$GITHUB_ROOT/$1"; }
clc() { ssh -t savorgserver "cd ~/GitHub/${1:-.} && claude ${@:2}"; }
cxc() { ssh -t savorgserver "cd ~/GitHub/${1:-.} && codex ${@:2}"; }
clw() { cd "$GITHUB_ROOT/$1" && claude --worktree; }

alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline --graph -15"
alias ga="git add"
alias gaa="git add -A"
unalias gc 2>/dev/null
gc() { git commit -m "$*"; }
alias gp="git push"
alias gpl="git pull"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gst="git stash"
alias gstp="git stash pop"

proj() {
  local dir
  dir=$(find "$GITHUB_ROOT" -maxdepth 1 -mindepth 1 -type d | fzf --prompt="Project: " --height=40%)
  [ -n "$dir" ] && cd "$dir"
}

alias vault="$HOME/.claude/claudecodex-vault.sh"
alias clmd="ls ~/.claude/commands/ | sed 's/.md$//'"

alias editzsh="nano ~/.zshrc && source ~/.zshrc"
alias edittmux="nano ~/.tmux.conf"
alias editclaude="nano $GITHUB_ROOT/CLAUDE.md"

alias srv="ssh savorgserver"

srvstatus() {
  echo "Uptime:   $(uptime | sed 's/.*up /up /;s/,  [0-9]* user.*//')"
  echo "Disk:     $(df -h / | awk 'NR==2{print $3 \" / \" $2 \" (\" $5 \" used)\"}')"
  echo "Memory:   $(memory_pressure 2>/dev/null | grep 'System-wide' | head -1 || vm_stat | head -5)"
  echo "Projects: $(ls "$GITHUB_ROOT" | wc -l | tr -d ' ') in $GITHUB_ROOT"
  echo "Tmux:     $(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ') sessions"
}

if [ -f "$HOME/.config/terminal/local.zsh" ]; then
  source "$HOME/.config/terminal/local.zsh"
fi
