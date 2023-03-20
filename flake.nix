{
  description = "themix-gui";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      srcs = builtins.fromJSON (builtins.readFile ./sources.json);
      fetch = src: pkgs.fetchgit { inherit (src) url rev sha256 fetchSubmodules; };
    in {
      packages = rec {
        default = themix-gui.withPlugins (ps: [ps.theme_oomox ps.icons_papirus]);

        themix-gui = pkgs.callPackage ./pkgs/themix-gui.nix {
          version = srcs.version;
          src = fetch srcs.themix-gui;
          python = pkgs.python3;
          inherit themix-gui availablePlugins;
        };

        availablePlugins = {
          theme_oomox = pkgs.callPackage ./pkgs/plugins/theme_oomox.nix {
            version = srcs.version;
            src = fetch srcs."plugins/theme_oomox";
          };
          icons_papirus = pkgs.callPackage ./pkgs/plugins/icons_papirus.nix {
            version = srcs.version;
            srcs = [
              (fetch srcs.themix-gui)
              (fetch srcs."plugins/icons_papirus/papirus-icon-theme")
            ];
          };
        };
      };
      apps = rec {
        update = flake-utils.lib.mkApp {
          drv = with pkgs; writeShellApplication {
            name = "update-themix-gui";
            runtimeInputs = [ nix-prefetch-git jq ];
            text = with lib; removePrefix "#!/usr/bin/env bash\n" (readFile ./update.sh);
          };
        };
      };
    });
}
