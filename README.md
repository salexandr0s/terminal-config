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
├── install.sh              # Idempotent bootstrap + symlink installer
├── zsh/
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
- optional `tmux` with sane defaults

## Install

```bash
git clone https://github.com/salexandr0s/terminal-config.git ~/GitHub/terminal-config
cd ~/GitHub/terminal-config
./install.sh
exec zsh
```

The installer will:

- install Homebrew packages from `Brewfile`
- install Oh My Zsh if missing
- install required Oh My Zsh custom plugins
- back up any existing `~/.zshrc`, `~/.zprofile`, and `~/.tmux.conf`
- symlink your live dotfiles to the repo versions
- create local override templates in `~/.config/terminal/`

Re-running the installer is safe.

## Symlinks

| Source            | Target         |
| ----------------- | -------------- |
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
