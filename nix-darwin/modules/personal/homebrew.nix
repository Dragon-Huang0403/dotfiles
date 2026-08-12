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
  ];

  homebrew.casks = [
    "nordvpn"
    "thunderbird"
    "wireshark-app"
    "zoom"
  ];
}
