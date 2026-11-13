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

Matt Pocock's skills are tracked in the `vendor/mattpocock-skills` Git submodule.
`setup.sh` discovers every `skills/**/SKILL.md` in that checkout and creates
relative directory symlinks in `agents/.agents/skills` before running Stow.
It updates moved skills and removes broken upstream links, while preserving
personal folders and unrelated symlinks when names collide. Duplicate upstream
skill names stop setup before links are changed.
The initial pin, `c55ee46073ed923f86ce59a5eb3b6d895095d1b7`, exactly matches
the previously copied skills. `vendor` is excluded from Stow.

Chrome DevTools skills use the same layout: the official repository is a
submodule at `vendor/chrome-devtools-mcp`, initially pinned to release
`chrome-devtools-mcp-v1.13.0` to match the installed npm CLI. Setup links only
`chrome-devtools-cli` into `agents/.agents/skills`; other bundled Chrome skills
are not installed. The CLI itself is installed separately with npm.
Setup initializes this submodule with depth 1 and sparse checkout for
`skills/chrome-devtools-cli`, without its nested `devtools-frontend` dependency.
Avoid blanket `git submodule update --init --recursive` commands if you want to
keep that dependency uninstalled. Sparse checkout also retains root files.
When upgrading it, update this submodule to the matching release, stage the
new pin, and run setup to refresh the skill links; no copying from npm is needed.

Booking skills come from the private SSH submodule
`vendor/booking-coding-agent-tools`, initially pinned to
`2df3576e72c3fff0e2e7006d515086b14d2d84b2`. GitLab SSH access is required.
Setup uses depth 1 and no nested submodules, with the full repository checked
out so all Booking skills are available under `vendor`. Only five skills under
`common/skills` are linked: `bk-cli`, `glab-cli`, `harness`, `servicemesh`, and `src-cli`.
The `BOOKING_SKILLS` list in setup controls skill links only;
new upstream skills are not linked automatically. Every selected skill must
exist before links are changed. Personal `acli`, `db-read`, `find-skills`, and the
loose `references` directory are left unchanged.

To initialize or upgrade Booking skills, run setup for the recorded version,
or explicitly select a new upstream version first:

```bash
git -C vendor/booking-coding-agent-tools fetch --depth=1 origin main
git -C vendor/booking-coding-agent-tools checkout --detach FETCH_HEAD
git diff --submodule=log -- vendor/booking-coding-agent-tools
# After reviewing the upgrade, record the pin before setup restores submodules:
git add vendor/booking-coding-agent-tools
./setup.sh
```

The original five copies, including installer metadata, are preserved in a
timestamped `backup/booking-skills-submodule-...` directory. Edit the selected
skill list to add another Booking skill, then rerun setup and stage its new link.

To restore the recorded submodule and restow existing skill links only
(without running the rest of setup or discovering new skills):

```bash
cd ~/dotfiles
git submodule update --init --recursive vendor/mattpocock-skills
mkdir -p ~/.agents/skills
stow --simulate --restow agents
stow --restow --verbose agents
```

To upgrade the upstream skills deliberately:

```bash
git -C vendor/mattpocock-skills fetch origin
git -C vendor/mattpocock-skills checkout --detach origin/HEAD
git diff --submodule=log -- vendor/mattpocock-skills
# After reviewing the upgrade, record the pin before setup restores submodules:
git add vendor/mattpocock-skills
./setup.sh
```

Setup automatically links newly added skills at the recorded submodule commit.
Stage the generated link changes under `agents/.agents/skills` along with the
new pin when committing the upgrade. No manual link creation is needed.
To discard an unstaged submodule upgrade and restore the recorded version, run
`git submodule update --init vendor/mattpocock-skills`.

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
