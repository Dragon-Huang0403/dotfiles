{
  description = "Multi-host nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    # Function to create a darwin system for a specific host
    mkDarwinSystem = hostname: nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/${hostname}.nix ];
      specialArgs = { inherit self; };
    };
  in {
    # Define configurations for each host
    darwinConfigurations = {
      # Build with: darwin-rebuild build --flake .#Subscript
      "Subscript" = mkDarwinSystem "Subscript";
      
      # Build with: darwin-rebuild build --flake .#WorkMac
      "WorkMac" = mkDarwinSystem "WorkMac";
      
      # Add more hosts as needed:
      # "MacBookPro" = mkDarwinSystem "MacBookPro";
    };

    # Optional: Set a default configuration
    darwinPackages = self.darwinConfigurations."Subscript".pkgs;
  };
}
