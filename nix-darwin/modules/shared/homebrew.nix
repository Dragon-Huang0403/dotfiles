{ ... }:

# Shared Homebrew base: dev tools, codecs/libraries, and fonts.
# Personal/consumer apps live in modules/personal/homebrew.nix and are
# concatenated onto these lists at merge time.

{
  # Homebrew needs to be installed on its own!
  homebrew.enable = true;

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
    "imagemagick"
    "jpeg-xl"
    "libmicrohttpd"
    "librist"
    "node"
    "numpy"
    "openblas"
    "openjpeg"
    "openvino"
    "pipx"
    "powerlevel10k"
    "prettier"
    "stow"
    "tesseract"
    "tldr"
    "unbound"
    "webp"
    "wireguard-tools"
  ];

  homebrew.casks = [
    "1password-cli"
    "1password"
    "alt-tab"
    "chatgpt"
    "claude-code"
    "claude"
    "font-fira-code"
    "font-hack"
    "font-inconsolata"
    "font-meslo-lg-nerd-font"
    "hammerspoon"
    "heptabase"
    "iterm2"
    "mitmproxy"
    "ngrok"
    "orbstack"
    "postico"
    "postman"
    "proxyman"
    "raycast"
    "shottr"
    "sioyek"
    "skim"
    "spotify"
    "stats"
    "thaw"
    "tomatobar"
    "whatsapp"
  ];
}
