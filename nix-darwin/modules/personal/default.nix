{ ... }:

# Personal profile layer — imported by profiles/personal.nix.
# Each module below adds its slice on top of the shared base.

{
  imports = [
    ./apps.nix
    ./homebrew.nix
    ./system.nix
  ];
}
