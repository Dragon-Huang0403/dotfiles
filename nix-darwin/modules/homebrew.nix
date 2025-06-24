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
    "switchkey"
    "tomatobar"
    "orbstack"
    "devtoys"
    "1password-cli"
  ];
  
  homebrew.brews = [ ];
}