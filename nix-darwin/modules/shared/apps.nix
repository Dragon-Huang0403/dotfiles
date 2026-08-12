{ pkgs, ... }:

{
  # Shared, universal CLI tooling. Personal-taste picks live in
  # modules/personal/apps.nix (concatenated onto this list at merge time).
  environment.systemPackages = with pkgs; [
    zsh-powerlevel10k
    tmuxinator
    glow
    
    atuin
    carapace

    neovim
    fd
    tree-sitter

    devcontainer

    tmux

    direnv

    eza # ls replacement

    lazygit

    codespell
    shellcheck

    # Golang
    go

    # Python tooling
    uv

    # Java
    jdk

    # Cloud / infra
    awscli2
    kubectl
    kubernetes-helm
    eksctl

    # Security
    gitleaks

    # CLI tools
    bat
    fzf
    gh
    delta
    htop
    jq
    jless
    pre-commit
    ripgrep
    tree
    yamllint
    zoxide
    unixtools.watch

    # Utilities
    wget
    cloc
  ];
}
