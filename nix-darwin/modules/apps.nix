{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    atuin
    zsh-powerlevel10k

    devcontainer

    tmux
    tmuxinator

    eza # ls replacement

    lazygit

    codespell
    shellcheck
    
    go
    nodejs_18_17_1
  ];
}