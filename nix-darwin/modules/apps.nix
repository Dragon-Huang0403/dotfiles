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
    glow
    htop
    jq
    jless
    pre-commit
    ripgrep
    tree
    yamllint
    zoxide

    # Utilities
    wget
    cloc
  ];
}
