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
    NSGlobalDomain = { };
    
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
  };

  # Security settings
  security.pam.enableSudoTouchIdAuth = true;

  # Power settings
  power = {
    sleep = {
      # Whether the power button can sleep the computer
      allowSleepByPowerButton = false;
    };
  };
}