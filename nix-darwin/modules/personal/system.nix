{ config, pkgs, lib, ... }:

# Personal profile — system.defaults overrides layered on top of
# modules/shared/system.nix. These attrsets deep-merge with the shared base.

{
  system.defaults = {
    dock = {
      # Position of the dock on screen. Type: null or one of "bottom", "left", "right"
      orientation = "left";

      # Persistent apps in Dock
      persistent-apps = [
        "/System/Applications/Apps.app"
        "/Applications/Spotify.app"
        "/Applications/Google Chrome.app"
        "/System/Applications/Calendar.app"
        "/Applications/iTerm.app"
        "/Applications/ChatGPT.app"
        "/Applications/Claude.app"
        "/Applications/Heptabase.app"
        "/Applications/WhatsApp.app"
      ];
    };

    CustomUserPreferences = {
      "org.hammerspoon.Hammerspoon" = {
        MJConfigFile = "~/.config/hammerspoon/init.lua";
      };
      "cc.ffitch.shottr" = {
        # After capture behaviour
        afterGrabCopy = true;
        afterGrabSave = true;
        afterGrabShow = true;
        areaCaptureMode = "editor";
        captureCursor = "auto";
        # Annotation defaults
        colorFormat = "HEX";
        defaultColor = "#FF0C01";
        # Save behaviour
        copyOnEsc = true;
        saveOnEsc = true;
        saveFormat = "Auto";
        realPixels = false;
        downscaleOnSave = false;
        # UI
        notificationType = "custom";
        thumbnailClosing = "manual";
        snappingMode = 2;
        windowShadow = "solid";
        windowSolidColor = "#404448";
        preferLargeWindow = true;
        expandableCanvas = true;
        headlessTextRendering = true;
        # OCR
        primaryOCRLang = "en-US";
        ocrRemoveBreaks = false;
        # Upload
        uploadMode = "none";
        # Scrolling capture
        scrollingSpeed = 2;
        scrollingMax = 20000;
        # Keyboard shortcuts (⇧⌘1-4 for capture modes, ^⌥⇧O for OCR)
        "KeyboardShortcuts_scrolling"  = ''{"carbonKeyCode":18,"carbonModifiers":768}'';
        "KeyboardShortcuts_anyWindow"  = ''{"carbonKeyCode":19,"carbonModifiers":768}'';
        "KeyboardShortcuts_area"       = ''{"carbonKeyCode":20,"carbonModifiers":768}'';
        "KeyboardShortcuts_fullscreen" = ''{"carbonKeyCode":21,"carbonModifiers":768}'';
        "KeyboardShortcuts_ocr"        = ''{"carbonModifiers":6400,"carbonKeyCode":31}'';
      };
    };
  };

  # Set Shottr defaultFolder with proper $HOME expansion
  system.activationScripts.shottrFolder.text = ''
    echo "Configuring Shottr default folder..."
    mkdir -p "$HOME/screenshots"
    defaults write cc.ffitch.shottr defaultFolder "$HOME/screenshots"
  '';
}
