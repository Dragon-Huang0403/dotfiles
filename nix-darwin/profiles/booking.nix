{ config, pkgs, lib, self, ... }:

{
  imports = [
    ../modules/shared/common.nix
    (import ../modules/shared/nix.nix { inherit self; })
    ../modules/booking            # resolves to modules/booking/default.nix
  ];

  # Personal profile - per-user identity only.
  # (hostPlatform, configurationRevision, stateVersion live in shared modules;
  #  hostName is intentionally left unmanaged so the profile doesn't rename the machine.)

  # Primary user for user-specific options (homebrew, dock, finder, etc.)
  system.primaryUser = "lohuang";
}
