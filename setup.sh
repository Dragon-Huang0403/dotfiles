#!/usr/bin/env bash

# Dotfiles Installation Script
# Reference: https://github.com/joshukraine/dotfiles/blob/master/setup.sh
#
# This script sets up dotfiles using GNU Stow to create symlinks from the
# dotfiles directory to the user's home directory. It handles conflicts by
# backing up existing files and performs system configuration for macOS.

# It can be run safely multiple times on the same machine. (idempotency)

# Exit immediately if any command exits with a non-zero status
set -e

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Print formatted messages with [DOTFILES] prefix
# Usage: dotfiles_echo "message" [printf arguments]
dotfiles_echo() {
  local fmt="$1"
  shift

  # shellcheck disable=SC2059
  printf "[DOTFILES] ${fmt}\\n" "$@"
}

# Backup a file that would conflict with stow
# Creates timestamped backups in the backup directory
# Arguments:
#   $1 - Relative path from HOME (e.g., ".zshrc" or ".config/git/config")
backup_stow_conflict() {
  local relpath="$1"
  local target="${HOME}/${relpath}"
  local timestamp=$(date +%Y-%m-%d-%H-%M-%S)
  local backup_dir="${DOTFILES}/backup/$(dirname "${relpath}")"
  local backup_file="${DOTFILES}/backup/${relpath}_${timestamp}.backup"

  # Skip if target doesn't exist
  if [ ! -e "${target}" ]; then
    dotfiles_echo "No file to backup: ${target}"
    return
  fi

  # Create backup directory and move the file
  dotfiles_echo "Conflict detected: ${relpath} - Backing up..."
  mkdir -p "${backup_dir}"
  dotfiles_echo "Moving ${target} to ${backup_file}"
  mv -v "${target}" "${backup_file}"
}

# Check for potential stow conflicts for a given package
# Backs up any existing files that would be replaced by stow
# Arguments:
#   $1 - Package directory name (e.g., "zsh", "git")
check_conflicts_for_package() {
  local package="$1"

  # Find all files in the package directory
  find "$package" -type f | while read -r filepath; do
    # Get the relative path from the package directory
    local relpath="${filepath#$package/}"  # e.g., ".aws/config"
    local target_path="${HOME}/${relpath}"

    # Skip if any parent directory is already a symlink
    # (stow will handle these automatically)
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
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
      backup_stow_conflict "$relpath"
    fi
  done
}

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================

# Ensure we're running on macOS
readonly OS_NAME=$(uname)
if [ "$OS_NAME" != "Darwin" ]; then
  dotfiles_echo "ERROR: This script only supports macOS. Detected: ${OS_NAME}"
  exit 1
fi

# Check for GNU Stow installation
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
sudo -v

# Set DOTFILES directory if not already set
if [ -z "$DOTFILES" ]; then
  export DOTFILES="${HOME}/dotfiles"
fi

# Verify DOTFILES directory exists
if [ ! -d "$DOTFILES" ]; then
  dotfiles_echo "ERROR: Dotfiles directory not found at: ${DOTFILES}"
  exit 1
fi

# ============================================================================
# SYSTEM CONFIGURATION
# ============================================================================

dotfiles_echo "Configuring system hostname..."

# Get current system names
readonly COMPUTER_NAME=$(scutil --get ComputerName)
readonly LOCAL_HOST_NAME=$(scutil --get LocalHostName)

# Set the HostName to match LocalHostName
sudo scutil --set HostName "$LOCAL_HOST_NAME"
readonly HOST_NAME=$(scutil --get HostName)

# Update NetBIOS name for consistency
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
if [ -z "$XDG_CONFIG_HOME" ]; then
  dotfiles_echo "Setting up XDG_CONFIG_HOME..."
  if [ ! -d "${HOME}/.config" ]; then
    mkdir -p "${HOME}/.config"
  fi
  export XDG_CONFIG_HOME="${HOME}/.config"
fi

# Setup local bin directory for user scripts
if [ ! -d "${HOME}/.local/bin" ]; then
  dotfiles_echo "Creating ~/.local/bin directory..."
  mkdir -p "${HOME}/.local/bin"
fi

# ============================================================================
# HOMEBREW PREFIX DETECTION
# ============================================================================

dotfiles_echo "Detecting system architecture..."

readonly ARCH="$(uname -m)"
if [ "$ARCH" == "arm64" ]; then
  dotfiles_echo "Apple Silicon detected - Using /opt/homebrew"
  readonly HOMEBREW_PREFIX="/opt/homebrew"
else
  dotfiles_echo "Intel Mac detected - Using /usr/local"
  readonly HOMEBREW_PREFIX="/usr/local"
fi

# ============================================================================
# STOW OPERATIONS
# ============================================================================

# Change to dotfiles directory (required for stow to work correctly)
cd "${DOTFILES}/"

# Define directories to ignore during stow operations
# Note: These are directory names as they appear in the dotfiles repo
readonly -a STOW_IGNORE_DIRECTORIES=(
  "backup"      # Backup directory for conflicts
  "iterm2"      # iTerm2 preferences (handled separately)
  ".git"        # Git repository files
  ".github"     # GitHub specific files
)

# Check for conflicts before stowing
dotfiles_echo "Checking for potential stow conflicts..."

for item in *; do
  # Process only directories that aren't in the ignore list
  if [ -d "$item" ] && [[ ! " ${STOW_IGNORE_DIRECTORIES[@]} " =~ " ${item} " ]]; then
    check_conflicts_for_package "$item"
  fi
done

echo

# Apply stow symlinks
dotfiles_echo "Creating symlinks with GNU Stow..."

for item in *; do
  # Process only directories that aren't in the ignore list
  if [ -d "$item" ] && [[ ! " ${STOW_IGNORE_DIRECTORIES[@]} " =~ " ${item} " ]]; then
    dotfiles_echo "Stowing ${item}..."
    stow -v "$item"/
  fi
done

echo

# ============================================================================
# COMPLETION
# ============================================================================

dotfiles_echo "Dotfiles setup complete!"

echo
echo "Possible next steps:"
echo "-> Set up 1Password CLI (https://developer.1password.com/docs/cli)"
echo "-> Restart your terminal to apply shell configuration"
echo "-> Review backed up files in: ${DOTFILES}/backup/"