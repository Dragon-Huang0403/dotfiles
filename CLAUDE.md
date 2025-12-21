# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal macOS dotfiles managed with GNU Stow (symlink manager) and Nix Darwin (system configuration). Configurations are organized by tool in separate directories that get symlinked to `~`.

## Commands

### Setup & Installation
```bash
# Initial setup (backs up conflicts, creates symlinks, configures system)
./setup.sh

# Re-run after adding new configs
./setup.sh
```

### Nix Darwin
```bash
# Rebuild system configuration (after modifying nix-darwin/)
sudo darwin-rebuild switch --flake ~/dotfiles/nix-darwin#Subscript

# Initial Nix Darwin installation (if darwin-rebuild not available)
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake ~/dotfiles/nix-darwin#Subscript
```

### Homebrew
```bash
# Install all packages from Brewfile
brew bundle --file=~/dotfiles/Brewfile

# Add new package to Brewfile and install
brew bundle dump --file=~/dotfiles/Brewfile --force
```

### Git Submodules
```bash
# Initialize/update submodules (tmux plugins, agents)
git submodule update --init --recursive
```

## Architecture

### Symlink Management (GNU Stow)
Each top-level directory represents a "package" that gets stowed to `~`:
- `zsh/` → shell config (`.zshrc`, `.zprofile`, `.zaliases`)
- `git/` → git config (`.gitconfig`, `.gitignore_global`)
- `tmux/` → tmux config (`.tmux.conf`, plugins via submodules)
- `ssh/` → SSH config
- `aws/` → AWS CLI profiles

**Excluded from stowing** (in `setup.sh`): `backup/`, `iterm2/`, `nix-darwin/`, `.git/`, `.github/`, `.vscode/`, `raycast_scripts/`

### Nix Darwin (nix-darwin/)
Multi-host flake configuration:
- `flake.nix` - Entry point with host definitions
- `hosts/` - Machine-specific configs (Subscript.nix, WorkMac.nix)
- `modules/` - Reusable modules (homebrew.nix, system.nix, apps.nix)

### Key Integrations
- **1Password**: SSH agent and secret management (lazy-loaded in `.zsecrets`)
- **Git signing**: SSH keys via 1Password with `allowed-signers`
- **Shell**: Oh My Zsh + Powerlevel10k + antidote plugins
- **Tmux**: Catppuccin theme, TPM plugin manager (submodule)

## Adding New Configurations

1. Create directory: `mkdir -p newapp/.config/newapp`
2. Add config files inside matching the target structure
3. Run `./setup.sh` to create symlinks
4. Conflicts are auto-backed up to `backup/` with timestamps
