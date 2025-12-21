# https://nix-darwin.github.io/nix-darwin/manual/index.html

{ config, pkgs, lib, ... }:

{
  imports = [
    ./apps.nix
    ./homebrew.nix
    ./overlays.nix
    ./system.nix
  ];

  # Nix settings
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;

  # Used for backwards compatibility
  system.stateVersion = 5;

  # Enable alternative shell support in nix-darwin.
  programs.zsh.enable = true;

  # iTerm2 preferences configuration
  system.activationScripts.iterm2Prefs.text = ''
    if [ -d "/Applications/iTerm.app" ]; then
      echo "Configuring iTerm2 preferences..."
      defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/iterm2"
      defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    fi
  '';
}