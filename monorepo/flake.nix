{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      scopeName = builtins.throw "Missing scope name in flake.nix - please define one.";

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            inherit (pkgs) lib;

            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                self.overlays.default
              ];
            };

            ourPackages = lib.filterAttrs (
              _: value: (value ? "${scopeName}Package")
            ) pkgs."${scopeName}Packages";

            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

            treefmt = treefmtEval.config.build.wrapper;
          in
          f {
            inherit
              lib
              ourPackages
              pkgs
              system
              treefmt
              treefmtEval
              ;
          }
        );
    in
    {
      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      packages = forEachSupportedSystem ({ ourPackages, ... }: ourPackages);

      devShells = forEachSupportedSystem (
        { pkgs, ourPackages, ... }:
        {
          default = pkgs.mkShell {
            inputsFrom = builtins.attrValues ourPackages;
          };
        }
      );

      overlays.default = final: prev: {
        "${scopeName}Packages" = final.callPackage ./pkgs/scope.nix { inherit scopeName; };
      };

      checks = forEachSupportedSystem (
        {
          lib,
          ourPackages,
          treefmtEval,
          ...
        }:
        let
          testsFrom =
            pkg:
            lib.mapAttrs' (name: value: {
              name = "${pkg.pname}-${name}";
              inherit value;
            }) (pkg.passthru.tests or { });

          ourTests = lib.foldlAttrs (
            acc: _: value:
            acc // (testsFrom value)
          ) { } ourPackages;
        in
        ourTests
        // {
          treefmt = treefmtEval.config.build.check self;
        }
      );
    };
}
