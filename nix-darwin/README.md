# Multi-Host Nix-Darwin Configuration

This configuration supports multiple macOS machines with shared and host-specific settings.

## Structure

```
nix-darwin/
├── flake.nix              # Main flake with multi-host support
├── hosts/                 # Host-specific configurations
│   ├── Subscript.nix      # Configuration for Subscript machine
│   └── WorkMac.nix        # Example work machine configuration
└── modules/               # Reusable modules
    ├── common.nix         # Shared settings across all hosts
    ├── apps.nix           # Common applications
    ├── homebrew.nix       # Homebrew packages
    ├── overlays.nix       # Custom package overlays
    ├── nix.nix            # Nix daemon settings
    └── system.nix         # MacOS System settings
```

## Usage

### On your current machine (Subscript):

```bash
darwin-rebuild switch --flake .#Subscript
```

### On a different machine:

1. Clone this repository
2. Create a new host file in `hosts/` (e.g., `hosts/MyMacBook.nix`)
3. Update `flake.nix` to add your host to `darwinConfigurations`
4. Run: `darwin-rebuild switch --flake .#MyMacBook`

## Adding a New Host

1. Create `hosts/YourHostname.nix`:

```nix
{ config, pkgs, lib, self, ... }:
{
  imports = [
    ../modules/common.nix
    (import ../modules/nix.nix { inherit self; })
  ];

  networking.hostName = "YourHostname";

  users.users.yourusername = {
    home = "/Users/yourusername";
  };

  # Host-specific settings...
}
```

2. Add to `flake.nix`:

```nix
darwinConfigurations = {
  # ... existing hosts ...
  "YourHostname" = mkDarwinSystem "YourHostname";
};
```

## Customization

- **Common settings**: Edit `modules/common.nix` for settings shared across all machines
- **Host-specific**: Edit files in `hosts/` for machine-specific settings
- **Apps**: Modify `modules/apps.nix` for common apps, or add to host files for specific ones
- **Homebrew**: Edit `modules/homebrew.nix` for common casks/brews
