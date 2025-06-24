{ config, pkgs, lib, self, ... }:

{
  imports = [
    ../modules/common.nix
    (import ../modules/nix.nix { inherit self; })
  ];

  # Host-specific settings for Subscript
  networking.hostName = "Subscript";
  
  # User-specific settings
  users.users.dragonhunag = {
    home = "/Users/dragonhunag";
  };

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set Git commit hash for darwin-version
  system.configurationRevision = self.rev or self.dirtyRev or null;
}