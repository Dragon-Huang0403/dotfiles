{ config, pkgs, lib, self, ... }:

{
  imports = [
    ../modules/common.nix
    (import ../modules/nix.nix { inherit self; })
  ];

  # Host-specific settings for WorkMac
  networking.hostName = "WorkMac";
  
  # User-specific settings (different username example)
  users.users.johndoe = {
    home = "/Users/johndoe";
  };

  # Machine-specific Finder settings
  system.defaults.finder = {
    NewWindowTarget = "Documents";
  };

  # Different dock orientation for work machine
  system.defaults.dock.orientation = "bottom";

  # Machine-specific screenshot location
  system.defaults.screencapture.location = "/Users/johndoe/Pictures/Screenshots";

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Work-specific apps (override or extend common apps)
  environment.systemPackages = with pkgs; [
    slack
    zoom-us
    docker
  ] ++ config.environment.systemPackages;

  # Work-specific Homebrew casks
  homebrew.casks = config.homebrew.casks ++ [
    "microsoft-teams"
    "visual-studio-code"
  ];
}