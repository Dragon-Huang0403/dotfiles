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
path=(
  $HOME/.nix-profile/bin             # nix-user packages
  /run/current-system/sw/bin         # nix-darwin system profile
  /nix/var/nix/profiles/default/bin  # default system profile
  /opt/{homebrew,local}/{,s}bin(N)   # brew
  $path
  $HOME/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $HOME/.local/bin(N)
  $HOME/subscript/scripts/local(N)
)

# For golang library
if command -v go &>/dev/null; then
  path+=("$(go env GOPATH)/bin")
fi

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER="${BROWSER:-open}"
fi

#
# Editors
#
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"
export PAGER="${PAGER:-less}"

#
# Regional Settings
#

export LANG="${LANG:-en_US.UTF-8}"

#
# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

#
# SSH
#
export SSH_AUTH_SOCK="$HOME/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# For setup eslint config globally, so it knows where to find eslint config from global node_modules
if command -v npm &>/dev/null; then
  export NODE_PATH=$(npm root -g)
fi

# For nvm lazy load with zsh-nvm plugin
export NVM_LAZY_LOAD=true

# Make Apple Terminal behave.
export SHELL_SESSIONS_DISABLE=1