# Multi-Profile Nix-Darwin Configuration

This configuration supports multiple macOS machines through **profiles** with
shared and profile-specific settings. A profile is a *chosen* identity (e.g.
`personal`, `work`) — it is deliberately decoupled from the machine's hostname,
so the same profile can be installed on any Mac.

## Structure

Each module is split into a **shared base** (`modules/shared/`) and a
**per-profile layer** (`modules/personal/`, and future `modules/<profile>/`). Nix
merges them: list options (`environment.systemPackages`, `homebrew.casks/brews/taps`)
concatenate, and `system.defaults.*` attrsets deep-merge. So the shared base and a
profile layer each contribute their slice with no conflicts (scalars like
`homebrew.enable` are set only in the shared base).

```
nix-darwin/
├── flake.nix                 # Main flake with multi-profile support
├── profiles/                 # Per-profile entrypoints
│   └── personal.nix          # imports shared base + personal layer; sets primaryUser
└── modules/
    ├── shared/               # Shared across all profiles
    │   ├── common.nix        # aggregates shared modules + cross-cutting settings
    │   ├── apps.nix          # universal CLI tooling
    │   ├── homebrew.nix      # dev tools / codecs / fonts (sets homebrew.enable)
    │   ├── overlays.nix      # custom package overlays
    │   ├── nix.nix           # Nix daemon + platform settings
    │   └── system.nix        # universal macOS system defaults
    └── personal/             # Personal profile layer
        ├── default.nix       # imports the personal modules below
        ├── apps.nix          # personal-taste CLI picks
        ├── homebrew.nix      # personal/consumer casks + brews + taps
        └── system.nix        # personal system.defaults (dock apps, Hammerspoon/Shottr…)
```

## Usage

Select the profile explicitly — there is no hostname-based default.

```bash
darwin-rebuild switch --flake .#personal
```

Or via the repo's installer, which passes the profile through:

```bash
PROFILE=personal ./setup.sh    # or: ./setup.sh personal
```

`setup.sh` errors out (listing available profiles) if `PROFILE` is unset or
names a profile that doesn't exist.

## Adding a New Profile

1. Create `profiles/<name>.nix`. Note `primaryUser` must match the target
   machine's macOS account name:

```nix
{ config, pkgs, lib, self, ... }:
{
  imports = [
    ../modules/shared/common.nix
    (import ../modules/shared/nix.nix { inherit self; })
    ../modules/<name>              # your profile layer, e.g. ../modules/work
  ];

  # Primary user for user-specific options (homebrew, dock, finder, etc.)
  system.primaryUser = "yourusername";
}
```

2. Create the profile layer `modules/<name>/` (a `default.nix` importing your
   per-profile `apps.nix` / `homebrew.nix` / `system.nix`, mirroring
   `modules/personal/`). Only the settings that differ from the shared base go here.

3. Add it to `flake.nix`:

```nix
darwinConfigurations = {
  # ... existing profiles ...
  "<name>" = mkDarwinSystem "<name>";
};
```

4. Build/apply: `PROFILE=<name> ./setup.sh` (or `darwin-rebuild switch --flake .#<name>`).

## Customization

- **Shared settings**: Edit `modules/shared/*.nix` for anything common to all profiles
- **Profile-specific**: Edit `modules/personal/*.nix` (or your profile's layer) for
  per-profile settings — dock apps, personal casks, personal-taste CLI tools
- **Apps**: Universal CLI tools go in `modules/shared/apps.nix`; personal picks in
  `modules/personal/apps.nix`
- **Homebrew**: Dev tools/fonts in `modules/shared/homebrew.nix`; consumer apps in
  `modules/personal/homebrew.nix`
