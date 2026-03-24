{ config, pkgs, lib, self, ... }:

{
  imports = [
    ../modules/common.nix
    (import ../modules/nix.nix { inherit self; })
  ];

  # Host-specific settings for Long's MacBook
  networking.hostName = "Longs-MacBook";

  # Primary user for user-specific options (homebrew, dock, finder, etc.)
  system.primaryUser = "xuanlong";

  # User-specific settings
  users.users.xuanlong = {
    home = "/Users/xuanlong";
  };

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
