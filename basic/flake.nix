{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

            treefmt = treefmtEval.config.build.wrapper self;
          in
          f {
            inherit
              system
              pkgs
              treefmt
              treefmtEval
              ;
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, treefmt, ... }:
        {
          default = pkgs.mkShell {
            packages = [
              treefmt
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      checks = forEachSupportedSystem (
        { treefmtEval, ... }: {
          treefmt = treefmtEval.config.build.check self;
        }
      );
    };
}
