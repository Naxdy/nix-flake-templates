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
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
            };

            nodejs = pkgs.nodejs_22;

            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

            treefmt = treefmtEval.config.build.wrapper;
          in
          f {
            inherit
              nodejs
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

      packages = forEachSupportedSystem (
        { pkgs, nodejs, ... }:
        {
          default = pkgs.callPackage ./default.nix { inherit nodejs; };
        }
      );

      devShells = forEachSupportedSystem (
        {
          nodejs,
          pkgs,
          system,
          treefmt,
          ...
        }:
        {
          default = pkgs.mkShell {
            packages = [
              treefmt
            ];

            inputsFrom = [ self.packages.${system}.default ];
          };
        }
      );
    };
}
