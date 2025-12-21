{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    atuin
    zsh-powerlevel10k
    carapace

    neovim
    fd
    tree-sitter

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