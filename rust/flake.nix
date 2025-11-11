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
      pname = builtins.trace "Missing package name in flake.nix - set one to enable building your project" null;

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
              overlays = [ self.overlays.default ];
            };

            treefmtEval = treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix { inherit pname; });

            treefmt = treefmtEval.config.build.wrapper;
          in
          f {
            inherit
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
          ...
        }:
        {
          default = self.devShells.${system}.full;

          full = pkgs.mkShell {
            packages = [
              treefmt
              pkgs.${pname}.passthru.rustToolchain
            ];

            inputsFrom = [ pkgs.${pname} ];
          };

          toolchainOnly = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.${pname}.passthru.rustToolchain
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      packages = forEachSupportedSystem (
        {
          pkgs,
          system,
          ...
        }:
        {
          default = self.packages.${system}.${pname};

          ${pname} = pkgs.${pname};

          inherit (pkgs.${pname}.passthru) docs;
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
        // (testsFrom pkgs.${pname})
      );

      overlays.default =
        final: prev:
        (final.lib.optionalAttrs (pname != null) {
          "${pname}" = final.callPackage ./default.nix {
            fenix = final.callPackage fenix { };
            craneLib = crane.mkLib final;
          };
        });
    };
}
