{ ... }:

{
  # Homebrew needs to be installed on its own!
  homebrew.enable = true;
  
  homebrew.casks = [
    "iterm2"
    "sioyek"
    "stats"
    "google-chrome"
    "shottr"
    "tomatobar"
    "orbstack"
    "devtoys"
    "1password-cli"
    "hammerspoon"
  ];
  
  homebrew.brews = [ ];
}