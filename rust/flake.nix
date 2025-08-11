{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    fenix.url = "github:nix-community/fenix";

    crane.url = "github:ipetkov/crane";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      fenix,
      crane,
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
              overlays = [ fenix.overlays.default ];
            };

            package = pkgs.callPackage ./default.nix { inherit crane; };

            treefmtEval = treefmt-nix.lib.evalModule pkgs (
              import ./treefmt.nix { inherit (package) rustToolchain cargoToml; }
            );

            treefmt = treefmtEval.config.build.wrapper;
          in
          f {
            inherit
              package
              pkgs
              system
              treefmt
              treefmtEval
              ;
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        {
          pkgs,
          treefmt,
          system,
          package,
          ...
        }:
        {
          default = self.devShells.${system}.full;

          full = pkgs.mkShell {
            packages = [
              treefmt
            ];

            inputsFrom = [ self.packages.${system}.default ];
          };

          toolchainOnly = pkgs.mkShell {
            nativeBuildInputs = [
              package.rustToolchain
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      packages = forEachSupportedSystem (
        {
          package,
          ...
        }:
        {
          default = package.package;

          inherit (package) docs;
        }
      );

      checks = forEachSupportedSystem (
        {
          pkgs,
          treefmtEval,
          system,
          ...
        }:
        let
          testsFrom =
            pkg:
            pkgs.lib.mapAttrs' (name: value: {
              name = "${pkg.pname}-${name}";
              inherit value;
            }) pkg.passthru.tests;
        in
        {
          treefmt = treefmtEval.config.build.check self;
        }
        // (testsFrom self.packages.${system}.default)
      );
    };
}
