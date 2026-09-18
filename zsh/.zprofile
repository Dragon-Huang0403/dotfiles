
# fpath for zsh functions and completions
fpath=(
  $HOME/.zsh/completions
  $fpath
)

# For golang library
if command -v go &>/dev/null; then
  path+=("$(go env GOPATH)/bin")
fi

#
# SSH
# 

# Disable this because conflict of ssh -A booking.com. 1password ssh agent don't allow add ca. causing ssh connection fails
# export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

#
# Editors
#
export EDITOR=vim
export VISUAL=vim
export PAGER=less

# Make Apple Terminal behave.
export SHELL_SESSIONS_DISABLE=1

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :