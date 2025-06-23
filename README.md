# Dotfiles

Personal dotfiles for macOS managed with GNU Stow and Nix Darwin.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/)
- GNU Stow: `brew install stow`
- [Nix](https://github.com/DeterminateSystems/nix-installer) (optional, for Nix Darwin)

## Installation

```bash
git clone https://github.com/Dragon-Huang0403/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script will:

- Back up existing configs to `backup/` with timestamps
- Create symlinks using GNU Stow
- Configure system settings
- Set up Nix Darwin (if Nix is installed)

## Directory Structure

```
dotfiles/
├── 1Password/     # SSH agent config
├── aws/           # AWS CLI config
├── bin/           # Personal scripts
├── git/           # Git configuration
├── nix-darwin/    # Nix Darwin flake
├── ssh/           # SSH config
├── zsh/           # Zsh configuration
└── setup.sh       # Installation script
```

## Usage

### Update configurations

```bash
# Re-run setup after changes
~/dotfiles/setup.sh
```

## How it works

GNU Stow creates symlinks from your home to this repo:

```
~/dotfiles/git/.gitconfig → ~/.gitconfig
~/dotfiles/zsh/.zshrc     → ~/.zshrc
```

Existing files are safely backed up before creating symlinks.

## Troubleshooting

- **Missing Stow**: Run `brew install stow`
- **Conflicts**: Check `~/dotfiles/backup/` for backed up files
- **Nix issues**: Ensure Nix is properly installed

## License

Free to use and modify.
