{
  description = "Multi-host nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    # Function to create a darwin system for a specific profile
    mkDarwinSystem = profile: nix-darwin.lib.darwinSystem {
      modules = [ ./profiles/${profile}.nix ];
      specialArgs = { inherit self; };
    };
  in {
    # Define configurations for each profile.
    # Select at install time via setup.sh (PROFILE=<name> ./setup.sh) or directly:
    #   darwin-rebuild build --flake .#personal
    darwinConfigurations = {
      "personal" = mkDarwinSystem "personal";
    };
  };
}
