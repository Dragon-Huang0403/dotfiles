#!/usr/bin/env bash

# =============================================================================
# DOTFILES INSTALLATION SCRIPT
# =============================================================================
# Purpose: Automate dotfiles setup using GNU Stow for symlink management
# Platform: macOS only
# Reference: https://github.com/joshukraine/dotfiles/blob/master/setup.sh
#
# OVERVIEW:
# This script sets up dotfiles using GNU Stow to create symlinks from the
# dotfiles directory to the user's home directory. It handles conflicts by
# backing up existing files and performs system configuration for macOS.
#
# FEATURES:
# - Idempotent: Can be run safely multiple times on the same machine
# - Conflict resolution: Backs up existing files before creating symlinks
# - System configuration: Sets up hostname and system preferences
# - Nix Darwin integration: Optionally configures Nix Darwin if installed
#
# PREREQUISITES:
# - macOS operating system
# - GNU Stow installed (brew install stow)
# - Dotfiles repository cloned to ~/dotfiles (or $DOTFILES if set)
#
# USAGE:
#   ./setup.sh
#
# DIRECTORY STRUCTURE:
# The dotfiles repo should be organized with each tool/config in its own
# directory. For example:
#   dotfiles/
#   ├── zsh/
#   │   ├── .zshrc
#   │   └── .zprofile
#   ├── git/
#   │   └── .gitconfig
#   └── vim/
#       └── .vimrc
#
# When stowed, these files will be symlinked to:
#   ~/.zshrc -> ~/dotfiles/zsh/.zshrc
#   ~/.gitconfig -> ~/dotfiles/git/.gitconfig
#   etc.
#
# =============================================================================

# Exit immediately if any command exits with a non-zero status
# This ensures the script stops on the first error
set -e

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Print formatted messages with [DOTFILES] prefix for consistent logging
# Usage: dotfiles_echo "message" [printf arguments]
# Examples:
#   dotfiles_echo "Simple message"
#   dotfiles_echo "File: %s" "/path/to/file"
#   dotfiles_echo "Progress: %d%%" 50
dotfiles_echo() {
  local fmt="$1"
  shift

  # shellcheck disable=SC2059
  printf "[DOTFILES] ${fmt}\\n" "$@"
}

# Backup a file that would conflict with stow to prevent data loss
# Creates timestamped backups in the backup directory for easy restoration
# 
# Arguments:
#   $1 - Relative path from HOME (e.g., ".zshrc" or ".config/git/config")
#
# Example:
#   backup_stow_conflict ".zshrc"
#   # Creates: ~/dotfiles/backup/.zshrc_2024-01-15-10-30-45.backup
#
# Notes:
#   - Preserves directory structure in backup location
#   - Adds timestamp to prevent overwriting previous backups
#   - Skips if target file doesn't exist
backup_stow_conflict() {
  local relpath="$1"
  local target="${HOME}/${relpath}"
  local timestamp backup_dir
  # Create timestamp for unique backup file naming
  timestamp=$(date +%Y-%m-%d-%H-%M-%S)
  # Preserve directory structure in backup location
  backup_dir="${DOTFILES}/backup/$(dirname "${relpath}")"
  # Full path to backup file with timestamp
  local backup_file="${DOTFILES}/backup/${relpath}_${timestamp}.backup"

  # Skip if target doesn't exist
  if [[ ! -e "${target}" ]]; then
    dotfiles_echo "No file to backup: ${target}"
    return
  fi

  # Create backup directory and move the file
  dotfiles_echo "Conflict detected: ${relpath} - Backing up..."
  mkdir -p "${backup_dir}"
  dotfiles_echo "Moving ${target} to ${backup_file}"
  mv -v "${target}" "${backup_file}"
}

# Check for potential stow conflicts for a given package before stowing
# Backs up any existing files that would be replaced by stow to prevent data loss
#
# This function is critical for safe dotfiles installation as it:
# - Finds all files that would be symlinked by stow
# - Checks if target locations already have non-symlink files
# - Backs up existing files before stow creates symlinks
# - Intelligently skips files when parent directory is already a symlink
#
# Arguments:
#   $1 - Package directory name (e.g., "zsh", "git")
#
# Example:
#   check_conflicts_for_package "zsh"
#   # Checks all files in zsh/ directory for conflicts
check_conflicts_for_package() {
  local package="$1"

  # Find all files in the package directory
  # Using -type f ensures we only process regular files, not directories or symlinks
  find "$package" -type f | while read -r filepath; do
    # Get the relative path from the package directory
    # Example: "zsh/.zshrc" becomes ".zshrc"
    local relpath="${filepath#$package/}"  # e.g., ".aws/config"
    # Full path where the symlink will be created
    local target_path="${HOME}/${relpath}"

    # Skip if any parent directory is already a symlink
    # This prevents unnecessary backups when stow will handle the entire
    # directory tree through an existing symlink
    # Example: If ~/.config is already a symlink, we don't need to backup
    # ~/.config/git/config as it's managed through the parent symlink
    local check_path="$target_path"
    local skip=false
    
    while [[ "$check_path" != "$HOME" && "$check_path" != "/" ]]; do
      check_path="$(dirname "$check_path")"
      if [ -L "$check_path" ]; then
        dotfiles_echo "Skipping ${relpath} (parent directory is symlink)"
        skip=true
        break
      fi
    done
    
    if $skip; then
      continue
    fi

    # Backup if the target exists and is not already a symlink
    # -e checks if file exists, -L checks if it's a symlink
    # We only backup real files, not existing symlinks
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
      backup_stow_conflict "$relpath"
    fi
  done
}

# Try to run Nix Darwin Flake for system configuration
# This function handles both initial installation and updates of Nix Darwin
# 
# Behavior:
# - If darwin-rebuild command exists: Runs switch with existing configuration
# - If darwin-rebuild missing: Installs Nix Darwin using nix run
#
# No Arguments required
#
# Prerequisites:
# - Nix package manager must be installed
# - Flake configuration must exist at ~/dotfiles/nix-darwin
darwin_rebuild() {
  dotfiles_echo "Nix is installed. Running Nix Darwin Flake..."
  echo

  if ! command -v darwin-rebuild >/dev/null; then
    dotfiles_echo "Nix Darwin is not installed. Installing..."
    # Initial installation requires nix run to bootstrap darwin-rebuild
    nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake ~/dotfiles/nix-darwin#Subscript
    dotfiles_echo "Nix Darwin Flake installed."
  else 
    # Subsequent runs can use the installed darwin-rebuild command
    sudo darwin-rebuild switch --flake ~/dotfiles/nix-darwin#Subscript
    dotfiles_echo "Nix Darwin Flake switched."
  fi
}

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================

# Ensure we're running on macOS
# This script uses macOS-specific commands like scutil and defaults
OS_NAME=$(uname)
if [ "$OS_NAME" != "Darwin" ]; then
  dotfiles_echo "ERROR: This script only supports macOS. Detected: ${OS_NAME}"
  exit 1
fi

# Check for GNU Stow installation
# Stow is the core tool used for symlink management
if ! command -v stow >/dev/null; then
  dotfiles_echo "ERROR: GNU Stow is required but not found."
  dotfiles_echo "Please install it with: brew install stow"
  exit 1
fi

# ============================================================================
# INITIALIZATION
# ============================================================================

dotfiles_echo "Initializing dotfiles setup..."

# Prompt for sudo access (needed for system configuration)
# This is required for:
# - Setting system hostname with scutil
# - Modifying system preferences with defaults
# - Running darwin-rebuild for Nix Darwin
sudo -v

# Set DOTFILES directory if not already set
# This allows users to override the default location by setting DOTFILES env var
if [ -z "$DOTFILES" ]; then
  export DOTFILES="${HOME}/dotfiles"
fi

# Verify DOTFILES directory exists
# This prevents confusing errors later if the directory is missing
if [ ! -d "$DOTFILES" ]; then
  dotfiles_echo "ERROR: Dotfiles directory not found at: ${DOTFILES}"
  dotfiles_echo "Please ensure the dotfiles repository is cloned to: ${DOTFILES}"
  exit 1
fi

# ============================================================================
# SYSTEM CONFIGURATION
# ============================================================================

dotfiles_echo "Configuring system hostname..."

# Get current system names
# macOS has three different hostname settings that should be consistent:
# - ComputerName: Friendly name shown in Finder
# - LocalHostName: Bonjour hostname (e.g., MacBook-Pro.local)
# - HostName: Unix hostname used by Terminal and command line tools
COMPUTER_NAME=$(scutil --get ComputerName)
LOCAL_HOST_NAME=$(scutil --get LocalHostName)

# Set the HostName to match LocalHostName for consistency
sudo scutil --set HostName "$LOCAL_HOST_NAME"
HOST_NAME=$(scutil --get HostName)

# Update NetBIOS name for consistency
# This ensures SMB/Windows file sharing uses the same name
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server.plist \
  NetBIOSName -string "$HOST_NAME"

# Display configured names
dotfiles_echo "ComputerName:  ==> [%s]" "$COMPUTER_NAME"
dotfiles_echo "LocalHostName: ==> [%s]" "$LOCAL_HOST_NAME"
dotfiles_echo "HostName:      ==> [%s]" "$HOST_NAME"
echo

# ============================================================================
# DIRECTORY SETUP
# ============================================================================

# Setup XDG config directory
# XDG Base Directory Specification defines where user config files should go
# Many modern CLI tools expect ~/.config to exist and use it for their configs
if [ -z "$XDG_CONFIG_HOME" ]; then
  dotfiles_echo "Setting up XDG_CONFIG_HOME..."
  if [ ! -d "${HOME}/.config" ]; then
    mkdir -p "${HOME}/.config"
  fi
  export XDG_CONFIG_HOME="${HOME}/.config"
fi

# Setup local bin directory for user scripts
# This follows the XDG convention for user-specific executables
# Add this to PATH in your shell config to use custom scripts
if [ ! -d "${HOME}/.local/bin" ]; then
  dotfiles_echo "Creating ~/.local/bin directory..."
  mkdir -p "${HOME}/.local/bin"
fi

# ============================================================================
# NIX DARWIN CONFIGURATION (OPTIONAL)
# ============================================================================

# Check if Nix is installed and run Darwin configuration if available
# This step is optional - the script will work without Nix
HAS_NIX_INSTALLED=$(command -v nix)
readonly HAS_NIX_INSTALLED
if [ -n "$HAS_NIX_INSTALLED" ]; then
  darwin_rebuild
else
  dotfiles_echo "Nix is not installed. Skipping Nix Darwin Flake..."
fi

echo

# ============================================================================
# STOW OPERATIONS
# ============================================================================

# Helper: check if array contains an element
# Used to determine if a directory should be excluded from stow operations
# Arguments:
#   $1 - Value to search for
#   $@ - Array elements to search through
# Returns: 0 if found, 1 if not found
contains_element() {
  local value="$1"; shift
  for e in "$@"; do [[ "$e" == "$value" ]] && return 0; done
  return 1
}

# Helper: loop over stow-able packages (exclude ignored dirs)
# Executes a given command for each valid package directory
# Arguments:
#   $@ - Command to execute with package name as argument
# Example:
#   for_each_stow_package check_conflicts_for_package
#   # Runs check_conflicts_for_package "zsh", check_conflicts_for_package "git", etc.
for_each_stow_package() {
  for item in *; do
    if [ -d "$item" ] && ! contains_element "$item" "${STOW_IGNORE_DIRECTORIES[@]}"; then
      "$@" "$item"
    fi
  done
}

# Change to dotfiles directory (required for stow to work correctly)
# Stow creates symlinks relative to the current directory
cd "${DOTFILES}/" || {
  dotfiles_echo "ERROR: Failed to change to dotfiles directory: ${DOTFILES}"
  exit 1
}

# Define directories to ignore during stow operations
# Note: These are directory names as they appear in the dotfiles repo
# The 'readonly' keyword ensures this array cannot be modified later
readonly -a STOW_IGNORE_DIRECTORIES=(
  "backup"      # Backup directory for conflicts
  "iterm2"      # iTerm2 preferences (handled separately)
  ".git"        # Git repository files
  ".github"     # GitHub specific files
  "nix-darwin"  # Nix Darwin configuration (handled by darwin_rebuild)
)

# Check for conflicts before stowing
# This is a safety measure to prevent accidental data loss
dotfiles_echo "Checking for potential stow conflicts..."
for_each_stow_package check_conflicts_for_package

echo

# Apply stow symlinks
dotfiles_echo "Creating symlinks with GNU Stow..."
# Function to stow a single package with verbose output
# Arguments:
#   $1 - Package directory name to stow
stow_package() {
  dotfiles_echo "Stowing ${1}..."
  # -v flag provides verbose output showing which symlinks are created
  stow -v "$1"/
}
for_each_stow_package stow_package

echo

# ============================================================================
# COMPLETION
# ============================================================================

dotfiles_echo "Dotfiles setup complete!"

echo
echo "Possible next steps:"
if [[ -z "$HAS_NIX_INSTALLED" ]]; then
  echo "-> Install Nix (https://github.com/DeterminateSystems/nix-installer)"
fi
if ! command -v op >/dev/null; then
  echo "-> Set up 1Password CLI (https://developer.1password.com/docs/cli)"
fi
echo "-> Restart your terminal to apply shell configuration"
echo "-> Review backed up files in: ${DOTFILES}/backup/"