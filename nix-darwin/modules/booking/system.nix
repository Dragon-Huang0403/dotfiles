{ config, pkgs, lib, ... }:

# Personal profile - system.defaults overrides layered on top of
# modules/shared/system.nix. These attrsets deep-merge with the shared base.

{
  system.defaults = {
    dock = {
      # Position of the dock on screen. Type: null or one of "bottom", "left", "right"
      orientation = "left";

      # Persistent apps in Dock
      persistent-apps = [
        "/System/Applications/Apps.app"
        "/Applications/Privileges.app"
        "/Applications/Slack.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/Applications/Spotify.app"
        "/Applications/Google Chrome.app"
        "/Applications/iTerm.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/ChatGPT.app"
        "/Applications/Heptabase.app"
        "/Applications/WhatsApp.app"
      ];
    };
  };
}
