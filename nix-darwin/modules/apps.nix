{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    atuin
    zsh-powerlevel10k

    neovim
    lunarvim

    devcontainer

    tmux
    tmuxinator

    eza # ls replacement

    lazygit

    codespell
    shellcheck
    
    go
  ];
}