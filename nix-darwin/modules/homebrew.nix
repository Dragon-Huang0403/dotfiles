{ ... }:

{
  # Homebrew needs to be installed on its own!
  homebrew.enable = true;

  homebrew.taps = [
    "heroku/brew"
  ];

  homebrew.brews = [
    "act"
    "aom"
    "binutils"
    "clang-format"
    "exiftool"
    "ffmpeg"
    "ghostscript"
    "glances"
    "gnutls"
    "heroku"
    "imagemagick"
    "jpeg-xl"
    "libmicrohttpd"
    "librist"
    "minikube"
    "node"
    "numpy"
    "openblas"
    "openjpeg"
    "openvino"
    "pipx"
    "prettier"
    "stow"
    "tesseract"
    { name = "tldr"; link = false; }
    "tlrc"
    "tor"
    "unbound"
    "webp"
    "wireguard-tools"
  ];

  homebrew.casks = [
    "1password-cli"
    "alt-tab"
    "chatgpt"
    "claude"
    "font-fira-code"
    "font-hack"
    "font-inconsolata"
    "font-meslo-lg-nerd-font"
    "google-chrome"
    "grammarly-desktop"
    "hammerspoon"
    "heptabase"
    "iterm2"
    "jordanbaird-ice"
    "mitmproxy"
    "ngrok"
    "nordvpn"
    "orbstack"
    "postico"
    "postman"
    "proxyman"
    { name = "raycast"; args = { require_sha = false; }; }
    "shottr"
    "sioyek"
    "skim"
    "spotify"
    "stats"
    "thunderbird"
    "tomatobar"
    "visual-studio-code"
    "whatsapp"
    "wireshark"
    "zoom"
  ];
}
