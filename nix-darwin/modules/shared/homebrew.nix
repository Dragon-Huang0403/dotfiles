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
    "prettier"
    "stow"
    "tesseract"
    { name = "tldr"; link = false; }
    "tlrc"
    "unbound"
    "webp"
    "wireguard-tools"
  ];

  homebrew.casks = [
    "alt-tab"
    "font-fira-code"
    "font-hack"
    "font-inconsolata"
    "font-meslo-lg-nerd-font"
    "iterm2"
    "mitmproxy"
    "ngrok"
    "orbstack"
    "postico"
    "postman"
    "proxyman"
    "sioyek"
    "skim"
    "stats"
    "thaw"
    "visual-studio-code"
    "wireshark-app"
  ];
}
