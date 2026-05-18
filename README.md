# terminal-config

Portable shell and terminal workflow based on my current macOS setup: `zsh` + `starship` + `fzf-tab` + `atuin` + `direnv` + light `tmux`.

This repo is meant to do two things:

1. Keep my terminal config under version control.
2. Let anyone else recreate the same setup with one repo and one installer.

This repo covers shell and multiplexer config. The Ghostty app config lives separately in [`ghostty-config`](https://github.com/salexandr0s/ghostty-config).

## Structure

```text
terminal-config/
├── Brewfile                # Terminal packages and fonts
├── bin/
│   ├── ai-notify           # Shared Claude/Codex completion notifier with cooldown support
│   ├── cl                  # Claude launcher rooted in ~/GitHub
│   ├── cl-fast             # Claude fast-mode launcher
│   ├── cl-deep             # Claude deep-mode launcher
│   ├── cx                  # Codex launcher rooted in ~/GitHub
│   ├── cx-fast             # Codex fast-mode launcher
│   └── cx-deep             # Codex deep-mode launcher
├── install.sh              # Idempotent bootstrap + symlink installer
├── zsh/
│   ├── .zshenv             # Always-on shell environment setup
│   ├── .zprofile           # Login-shell setup
│   ├── .zshrc              # Interactive shell config
│   ├── local.example.zsh   # Optional private overrides
│   └── local.example.zshenv
├── tmux/
│   └── .tmux.conf          # Lightweight tmux setup
└── README.md
```

## What You Get

- `zsh` with Oh My Zsh
- `starship` prompt
- `fzf-tab` completion menus that feel closer to `fish`
- `zsh-autosuggestions` and `zsh-syntax-highlighting`
- `atuin` history search on `Ctrl-R`
- `direnv` for per-project env loading
- `zoxide` for smarter directory jumps
- `eza`, `bat`, `lazygit`, `yazi`
- GitHub-aware `cl` / `cx` launchers for `claude` and `codex`
- shared `fast` / `normal` / `deep` assistant launchers
- shared `ai-notify` helper used by both Claude and Codex with cooldown-based smart notify
- optional `tmux` with sane defaults

## Install

```bash
git clone https://github.com/salexandr0s/terminal-config.git ~/GitHub/terminal-config
cd ~/GitHub/terminal-config
./install.sh
exec zsh
```

The installer will:

- ensure `~/GitHub` exists
- install Homebrew packages from `Brewfile`
- install Oh My Zsh if missing
- install required Oh My Zsh custom plugins
- back up any existing `~/.zshenv`, `~/.zshrc`, `~/.zprofile`, and `~/.tmux.conf`
- symlink your live dotfiles to the repo versions
- create local override templates in `~/.config/terminal/`

Re-running the installer is safe.

## Symlinks

| Source            | Target         |
| ----------------- | -------------- |
| `zsh/.zshenv`     | `~/.zshenv`    |
| `zsh/.zshrc`      | `~/.zshrc`     |
| `zsh/.zprofile`   | `~/.zprofile`  |
| `tmux/.tmux.conf` | `~/.tmux.conf` |

## Local Overrides

Anything private, machine-specific, or not fit for Git goes into:

- `~/.config/terminal/local.zshenv`
- `~/.config/terminal/local.zsh`

The installer creates these from the example files if they do not exist.

Use those files for things like:

- API keys
- keychain-backed exports
- machine-specific paths
- experimental aliases or functions

## Notes

- The shell config is written for macOS and Homebrew on Apple Silicon.
- It will still work on Intel macOS with small path edits.
- `tmux` is optional. If you do not use it, the config does not interfere with normal shell usage.
- If you want the same terminal emulator look and keybinds, pair this repo with `ghostty-config`.

## Customization

Common things to change:

- swap `starship` for another prompt
- add or remove aliases in `zsh/.zshrc`
- remove `tmux` entirely if you do not use it
- add personal env setup in `~/.config/terminal/local.zshenv`

By default, `cl` and `cx` run inside `~/GitHub/<project>`:

```bash
cl            # open claude in ~/GitHub
cl pnevma     # open claude in ~/GitHub/pnevma
cl-fast       # open claude in fast mode
cl-deep       # open claude in deep mode
cx            # open codex in ~/GitHub
cx pnevma     # open codex in ~/GitHub/pnevma
cx-fast       # open codex in fast mode
cx-deep       # open codex in deep mode
```

If the first argument is not a known project directory, the launcher passes it through to the underlying tool. `cx` also refreshes the generated Codex config before startup and prints the active mode/profile/reasoning banner because Codex's built-in footer is currently less informative than Claude's status line.

`ai-notify` defaults to smart notify via a cooldown window. Local overrides:

```bash
export AI_NOTIFY_ALWAYS=1
export AI_NOTIFY_COOLDOWN_SECONDS=10
export AI_NOTIFY_SOUND=/System/Library/Sounds/Funk.aiff
```

## Verification

After install:

```bash
zsh -n ~/.zshrc
tmux -f ~/.tmux.conf start-server \; kill-server
```

Open a new shell and confirm:

- `Tab` completion opens a richer selector
- `Ctrl-R` uses `atuin`
- `direnv` loads `.envrc` files when entering a project
- `starship` is active
