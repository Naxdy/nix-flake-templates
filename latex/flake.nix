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

            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

            treefmt = treefmtEval.config.build.wrapper;
          in
          f {
            inherit system pkgs treefmt;
          }
        );
    in
    {
      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      packages = forEachSupportedSystem (
        { pkgs, ... }:
        {
          default = pkgs.stdenv.mkDerivation {
            pname = builtins.throw "Missing package name in flake.nix";
            version = builtins.throw "Missing package version in flake.nix";

            src = self;

            nativeBuildInputs = [
              pkgs.texliveFull
            ];

            configurePhase = ''
              mkdir -p .latex-home

              export HOME=$PWD/.latex-home
            '';

            buildPhase = ''
              find . -type f -name "*.tex" -print0 | while read -d $'\0' f
              do
                pdflatex "$f"
              done
            '';

            installPhase = ''
              find . -type f -name "*.pdf" -print0 | while read -d $'\0' f
              do
                install -Dm644 "$f" "$out/$f"
              done
            '';
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, treefmt, ... }:
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.texliveFull
              treefmt
            ];
          };
        }
      );
    };
}
