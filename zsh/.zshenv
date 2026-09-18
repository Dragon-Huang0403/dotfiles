#!/bin/zsh
##? .zshenv - Zsh environment file, loaded always.

export ZDOTDIR=${ZDOTDIR:-$HOME}

# Reference: https://github.com/mattmc3/zdotdir/blob/d6e3c224d864eb5e3d7c9185a30e117e3c1d31eb
#
# XDG
#

# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$HOME/.xdg}

for xdgdir in XDG_{CONFIG,CACHE,DATA,STATE}_HOME XDG_RUNTIME_DIR; do
  [[ -e ${(P)xdgdir} ]] || mkdir -p ${(P)xdgdir}
done

#
# Brew
#
eval "$(/opt/homebrew/bin/brew shellenv)"

#
# Paths
#

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath cdpath mailpath

# set the list of directories that `cd` searches
# cdpath=(
#   ~/Projects
#   $cdpath
# )

# Set the list of directories that zsh searches for commands in order.
# PATH=
path=(
  $HOME/.nix-profile/bin             # nix-user packages
  /run/current-system/sw/bin         # nix-darwin system profile
  /nix/var/nix/profiles/default/bin  # default system profile
  /opt/{homebrew,local}/{,s}bin(N)   # brew
  $path
  $HOME/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $HOME/.local/bin(N)
  $HOME/Library/Android/sdk/platform-tools
  $HOME/Library/Android/sdk/emulator
  $HOME/fvm/default/bin              # fvm global SDK (replaces $HOME/flutter/flutter/bin)
  $HOME/.pub-cache/bin
)

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER="${BROWSER:-open}"
fi

#
# Regional Settings
#

export LANG="${LANG:-en_US.UTF-8}"


# For nvm lazy load with zsh-nvm plugin
export NVM_LAZY_LOAD=true

export SRC_ENDPOINT=https://sourcegraph.booking.com
