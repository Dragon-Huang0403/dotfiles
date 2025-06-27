#!/bin/zsh
#
# .zshrc - Run on interactive Zsh session.
#

#
# Profiling
#

[[ "$ZPROFRC" -ne 1 ]] || zmodload zsh/zprof
alias zprofrc="ZPROFRC=1 zsh"

#
# Zstyles
#

# Load .zstyles file with customizations.
[[ -r ${ZDOTDIR:-$HOME}/.zstyles ]] && source ${ZDOTDIR:-$HOME}/.zstyles

#
# Antidote
#

# Author Configuration: https://github.com/mattmc3/zdotdir

# Clone antidote if necessary.
# [[ -e $ZDOTDIR/.antidote ]] ||
#   git clone --depth=1 https://github.com/mattmc3/antidote.git $ZDOTDIR/.antidote

# # Setup antidote plugins.
# ANTIDOTE_HOME=$ZDOTDIR/.antidote/.plugins
# source $ZDOTDIR/.antidote/antidote.zsh
# antidote load

# 
# Local settings/overrides.
# 
# [[ -f $ZDOTDIR/.zshrc_local ]] && $ZDOTDIR/.zshrc_local


# 
# Oh My Zsh
# 

ZSH_THEME="powerlevel10k/powerlevel10k"
export ZSH="$HOME/.oh-my-zsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf-tab zsh-nvm)
source $ZSH/oh-my-zsh.sh

# 
# Powerlevel10k
# 

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme

#
# Aliases
#

[[ -r ${ZDOTDIR:-$HOME}/.zaliases ]] && source ${ZDOTDIR:-$HOME}/.zaliases

# 
# Command Tools
# 

eval "$(zoxide init zsh)"

# 
# Atuin, Shell history
# 

eval "$(atuin init zsh --disable-up-arrow)"

#
# Local zshrc
#
[[ -r ${ZDOTDIR:-$HOME}/.zshrc_local ]] && source ${ZDOTDIR:-$HOME}/.zshrc_local

# Finish profiling by calling zprof.
[[ "$ZPROFRC" -eq 1 ]] && zprof
[[ -v ZPROFRC ]] && unset ZPROFRC

# Always return success
true