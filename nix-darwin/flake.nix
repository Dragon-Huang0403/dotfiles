{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
      go
      tmux
      zsh-powerlevel10k
      lazygit
    ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      security.pam.enableSudoTouchIdAuth = true;
      nix.useDaemon = true;
      nix.enable = false;

      system.defaults = {
        dock.autohide = true;
        dock.mru-spaces = false;
        dock.orientation = "left";
        dock.appswitcher-all-displays = true;
        finder.AppleShowAllExtensions = true;
        finder.FXPreferredViewStyle = "clmv";
        screencapture.location = "~/screenshots";
        screensaver.askForPasswordDelay = 10;
      };

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

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
      homebrew.brews = [
      ];

      system.activationScripts.iterm2Prefs.text = ''
        if [ -d "/Applications/iTerm.app" ]; then
          echo "Configuring iTerm2 preferences..."
          defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/iterm2"
          defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
        fi
      '';
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Subscript
    darwinConfigurations."Subscript" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
