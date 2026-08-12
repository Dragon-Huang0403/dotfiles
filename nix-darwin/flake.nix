{
  description = "Multi-host nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    # Unstable, pulled in per-package via overlays for tools where the stable
    # channel lags too far behind. See modules/shared/overlays.nix.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nixpkgs-unstable }:
  let
    # Keep in sync with nixpkgs.hostPlatform in modules/shared/nix.nix
    system = "aarch64-darwin";

    # Function to create a darwin system for a specific profile
    mkDarwinSystem = profile: nix-darwin.lib.darwinSystem {
      modules = [ ./profiles/${profile}.nix ];
      specialArgs = {
        inherit self;
        pkgs-unstable = import nixpkgs-unstable { inherit system; };
      };
    };
  in {
    # Define configurations for each profile.
    # Select at install time via setup.sh (PROFILE=<name> ./setup.sh) or directly:
    #   darwin-rebuild build --flake .#personal
    darwinConfigurations = {
      "personal" = mkDarwinSystem "personal";
      "booking" = mkDarwinSystem "booking";
    };
  };
}
