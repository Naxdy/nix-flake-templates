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
      packageJSON = builtins.fromJSON (builtins.readFile ./package.json);

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      nodejs = builtins.throw "Missing nodejs version, pin one in flake.nix";
      pnpm = builtins.throw "Missing pnpm version, pin one in flake.nix";

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                self.overlays.default
              ];
            };

            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

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
      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      packages = forEachSupportedSystem (
        { pkgs, ... }:
        {
          default = pkgs."${packageJSON.name}";
        }
      );

      devShells = forEachSupportedSystem (
        {
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

      checks = forEachSupportedSystem (
        { pkgs, treefmtEval, ... }:
        let
          testsFrom =
            pkg:
            pkgs.lib.mapAttrs' (name: value: {
              name = "${pkg.pname}-${name}";
              inherit value;
            }) (pkg.passthru.tests or { });
        in
        (testsFrom pkgs."${packageJSON.name}")
        // {
          treefmt = treefmtEval.config.build.check self;
        }
      );

      overlays.default = final: prev: {
        "${packageJSON.name}" = final.callPackage ./default.nix {
          nodejs = final.${nodejs};
          pnpm = (final.${pnpm}).override {
            nodejs = final.${nodejs};
          };
        };
      };
    };
}
