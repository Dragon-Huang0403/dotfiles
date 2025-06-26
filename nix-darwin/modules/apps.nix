{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    atuin
    zsh-powerlevel10k
    tmux

    lazygit

    codespell
    shellcheck
    
    go
    nodejs_18_17_1
  ];
}