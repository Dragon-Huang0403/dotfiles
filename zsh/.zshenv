#!/bin/zsh
##? .zshenv - Zsh environment file, loaded always.

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-~/.config}
export ZDOTDIR=${ZDOTDIR:-$HOME}

# Use .zprofile for remaining environment.
source "${ZDOTDIR:-$HOME}/.zprofile"