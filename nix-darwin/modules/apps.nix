{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    atuin
    zsh-powerlevel10k
    carapace

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