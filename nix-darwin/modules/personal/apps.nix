{ pkgs, ... }:

# Personal-taste CLI packages. These concatenate onto the shared
# environment.systemPackages list in modules/shared/apps.nix.

{
  environment.systemPackages = with pkgs; [
    zsh-powerlevel10k
    tmuxinator
    glow
  ];
}
