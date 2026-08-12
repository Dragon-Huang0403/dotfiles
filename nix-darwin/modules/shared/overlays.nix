{ pkgs, pkgs-unstable, ... }:

{
  nixpkgs.overlays = [
    # Packages taken from nixpkgs-unstable because the pinned stable channel
    # lags: stable 25.11 is frozen at atuin 18.10.0.
    (final: prev: {
      inherit (pkgs-unstable) atuin;
    })

    (final: prev: {
      nodejs_18_17_1 = prev.stdenv.mkDerivation {
        pname   = "nodejs";
        version = "18.17.1";

        src = prev.fetchurl {
          url    = "https://nodejs.org/dist/v18.17.1/node-v18.17.1-darwin-arm64.tar.gz";
          hash   = "sha256-GMpxbqV1IrkEc3d8ufh4Rn93/fgm03vrFaCIn910Uz4=";
        };

        installPhase = ''
          mkdir -p $out
          tar -xzf $src --strip-components=1 -C $out
        '';
      };
    })
  ];
}