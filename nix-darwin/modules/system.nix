{ config, pkgs, lib, ... }:

{
  # System-wide defaults from mathiasbynens/dotfiles/.macos
  system.defaults = {
    
    # Dock settings
    dock = {
      # Automatically hide and show the Dock
      autohide = true;
      
      # Remove the auto-hiding Dock delay
      autohide-delay = 0.0;
      
      # Remove the animation when hiding/showing the Dock
      autohide-time-modifier = 0.0;
      
      # Set the icon size of Dock items to 36 pixels
      tilesize = 36;
      
      # Change minimize/maximize window effect
      mineffect = "scale";
      
      # Minimize windows into their application's icon
      minimize-to-application = true;
      
      # Enable spring loading for all Dock items
      enable-spring-load-actions-on-all-items = true;
      
      # Show indicator lights for open applications in the Dock
      show-process-indicators = true;
      
      # Don't animate opening applications from the Dock
      launchanim = false;
      
      # Speed up Mission Control animations
      expose-animation-duration = 0.1;
      
      # Don't group windows by application in Mission Control
      # (i.e. use the old Exposé behavior instead)
      expose-group-apps = false;
      
      # Disable Dashboard
      dashboard-in-overlay = true;
      
      # Don't automatically rearrange Spaces based on most recent use
      mru-spaces = false;
      
      # Show only open applications in the Dock
      static-only = false;
      
      # Don't show recent applications in Dock
      show-recents = false;

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
        "/Applications/Visual Studio Code.app"
        "/Applications/LINE.app"
        "/Applications/WhatsApp.app"
      ];
      
      # No folder stacks (e.g. remove Downloads)
      persistent-others = [ ];

      # Make Dock icons of hidden applications translucent
      showhidden = true;
      
      # Show the Dock on all displays
      appswitcher-all-displays = true;

     # Position of the dock on screen. Type: null or one of “bottom”, “left”, “right”
      orientation = "left";
    };
    
    # Finder settings
    finder = {
      # Show hidden files by default
      AppleShowAllFiles = true;
      
      # Show all filename extensions
      AppleShowAllExtensions = true;
      
      # Show status bar
      ShowStatusBar = true;
      
      # Show path bar
      ShowPathbar = true;
      
      # Display full POSIX path as Finder window title
      _FXShowPosixPathInTitle = true;
      
      # Keep folders on top when sorting by name
      _FXSortFoldersFirst = true;
      
      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";
      
      # Disable the warning when changing a file extension
      FXEnableExtensionChangeWarning = false;
      
      # Use list view in all Finder windows by default
      # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
      FXPreferredViewStyle = "Nlsv";

      # Change the default folder shown in Finder windows. “Other” corresponds to the value of NewWindowTargetPath. The default is unset (“Recents”).
      # Type: null or one of “Computer”, “OS volume”, “Home”, “Desktop”, “Documents”, “Recents”, “iCloud Drive”, “Other”
      NewWindowTarget = "Home";
    };
    
    # Trackpad settings
    trackpad = {};
    
    # NSGlobalDomain - General UI/UX settings
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
    };
    
    # Screenshot settings
    screencapture = {
      # Save screenshots to the desktop
      location = "~/screenshots";
      
      # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
      type = "png";
      
      # Disable shadow in screenshots
      disable-shadow = true;
    };
    
    # Other system settings
    loginwindow = {};
    
    # Set the timezone; see `sudo systemsetup -listtimezones` for other values
    # Commented out since this varies by location
    # time.timeZone = "America/New_York";
    
    
    # Screensaver settings
    screensaver = {
      # Require password immediately after sleep or screen saver begins
      askForPassword = true;
      askForPasswordDelay = 0;
    };
    
    # Spaces settings
    spaces = {
      # Don't automatically rearrange Spaces based on most recent use
      spans-displays = false;
    };
    
    # Activity Monitor settings
    ActivityMonitor = {
      # Show the main window when launching Activity Monitor
      OpenMainWindow = true;
      
      # Visualize CPU usage in the Activity Monitor Dock icon
      IconType = 5;
      
      # Show all processes in Activity Monitor
      ShowCategory = 100;
      
      # Sort Activity Monitor results by CPU usage
      SortColumn = "CPUUsage";
      SortDirection = 0;
    };
    
    # Disable Notification Center and remove the menu bar icon
    # Commented out as this might be too aggressive
    # menuExtraClock.IsAnalog = false;
    
    
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
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Screenshots - all disabled (using Shottr instead)
          "28" = { enabled = 0; };  # Save picture of screen as file (⇧⌘3)
          "29" = { enabled = 0; };  # Copy picture of screen to clipboard (^⇧⌘3)
          "30" = { enabled = 0; };  # Save picture of selected area as file (⇧⌘4)
          "31" = { enabled = 0; };  # Copy picture of selected area to clipboard (^⇧⌘4)
          # Spotlight - disabled so Raycast can use ⌘Space
          "64" = { enabled = 0; };  # Show Spotlight search (⌘Space)
          "65" = { enabled = 0; };  # Show Finder search window (⌥⌘Space)
        };
      };
    };
  };

  # Security settings - Touch ID for sudo (reattach fixes Touch ID in tmux/screen)
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Power settings
  power = {
    sleep = {
      # Whether the power button can sleep the computer
      allowSleepByPowerButton = false;
    };
  };

  # Set Shottr defaultFolder with proper $HOME expansion
  system.activationScripts.shottrFolder.text = ''
    echo "Configuring Shottr default folder..."
    mkdir -p "$HOME/screenshots"
    defaults write cc.ffitch.shottr defaultFolder "$HOME/screenshots"
  '';
}
