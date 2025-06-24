{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    go
    tmux
    zsh-powerlevel10k
    lazygit
    shellcheck
    codespell
    nodejs_18_17_1
  ];
}