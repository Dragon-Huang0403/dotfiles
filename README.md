# dotfiles

Personal dotfiles managed with GNU Stow for macOS.

## Prerequisites

- macOS
- Nix installed using [Determinate System’s Nix Installer for the shell](https://github.com/DeterminateSystems/nix-installer)
- [Homebrew](https://brew.sh/)
- GNU Stow: `brew install stow`

## Installation

```bash
git clone https://github.com/Dragon-Huang0403/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake ~/dotfiles/nix-darwin#Subscript
```

## Update the config

```bash
~/dotfiles/setup.sh
darwin-rebuild switch --flake ~/dotfiles/nix-darwin#Subscript
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
