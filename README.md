# dotfiles

Personal dotfiles managed with GNU Stow for macOS.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/)
- GNU Stow: `brew install stow`

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## What it does

- Creates symlinks for configuration files using GNU Stow
- Backs up existing files to `backup/` with timestamps
- Configures macOS system settings
- Sets up iTerm2 preferences (if installed)

## Structure

Each directory represents a package that will be symlinked to `$HOME`:
- `git/` → Git configuration
- `zsh/` → Zsh shell configuration
- `1Password/` → 1Password SSH agent config
- etc.

Directories excluded from stowing:
- `backup/` - Conflict backups
- `iterm2/` - iTerm2 preferences (handled separately)
- `.git/`, `.github/` - Repository files

## Safety

The script is idempotent and can be run multiple times. Existing files are backed up before being replaced.