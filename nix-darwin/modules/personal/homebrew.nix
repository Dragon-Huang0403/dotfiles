{ ... }:

# Personal Homebrew layer: consumer apps + personal tooling.
# These entries concatenate onto the shared lists in modules/shared/homebrew.nix.

{
  homebrew.taps = [
    "heroku/brew"
  ];

  homebrew.brews = [
    "heroku"
    "minikube"
    "powerlevel10k"
    "tor"
  ];

  homebrew.casks = [
    "1password"
    "1password-cli"
    "chatgpt"
    "claude"
    "google-chrome"
    "grammarly-desktop"
    "hammerspoon"
    "heptabase"
    "nordvpn"
    "raycast"
    "shottr"
    "spotify"
    "thunderbird"
    "tomatobar"
    "whatsapp"
    "zoom"
  ];
}
