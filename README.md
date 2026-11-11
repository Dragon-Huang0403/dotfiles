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

### Agent skills

The `agents` package uses Stow's default directory folding so each skill is
installed as a directory symlink. Other packages use `--no-folding`.
Keep `~/.agents/skills` as a real directory so separately installed skills can
coexist with dotfiles-managed skills.

To update only agent skills (without running the rest of setup):

```bash
cd ~/dotfiles
mkdir -p ~/.agents/skills
stow --simulate --restow agents
stow --restow --verbose agents
```

When migrating an older installation with individual file symlinks, first move
existing directories whose names occur under `agents/.agents/skills` into a
new timestamped `backup/skills-directory-links-.../` directory. Preserve the
complete directories, including local-only files and links; do not delete them
or use `--adopt`. Leave unrelated installed skills and `.system` in place.
Then run the commands above. If simulation reports a conflict, restore the
backed-up directories and resolve the conflict before applying Stow.

The November 2026 migration also backed up the obsolete `claude-handoff`
directory with its broken link. Local-only `code-review` metadata and scripts
remain in the migration backup rather than being added to the source skill.

Verify that each managed skill directory is a symlink and its `SKILL.md` is
readable. Restart Codex if the skills do not appear automatically, then check
its skill selector. Existing enable/disable settings still apply.

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
