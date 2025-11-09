{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  description = "Flake templates that make sense";

  outputs =
    {
      self,
      treefmt-nix,
      nixpkgs,
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

      devShells = forEachSupportedSystem (
        { pkgs, treefmt, ... }:
        {
          default = pkgs.mkShell {
            packages = [ treefmt ];
          };
        }
      );

      checks = forEachSupportedSystem (
        { treefmtEval, ... }:
        {
          treefmt = treefmtEval.config.build.check self;
        }
      );

      templates = {
        rust = {
          path = ./rust;
          description = "Starter flake for rust projects, using `crane` and `fenix`, as well as `treefmt` for project-wide formatting.";
          welcomeText = ''
            # Getting Started
            - run `nix develop .#toolchainOnly --command cargo init` to initialize a rust project
            - enter a dev shell with `nix develop` or `direnv`
            - get rusty
          '';
        };

        pnpm = {
          path = ./pnpm;
          description = "Starter flake for nodejs projects using `pnpm`, as well as `treefmt` for project-wide formatting.";
          welcomeText = ''
            # Getting Started
            - enter a dev shell with `nix develop` or `direnv`
            - initialize your pnpm project

            # Note
            The project has been initialized with a stub `package.json` file. You may want to remove / regenerate it with proper information.
          '';
        };

        python-nn = {
          path = ./python-nn;
          description = "Starter flake for Python projects intended for deep learning applications, with uv.";
          welcomeText = ''
            # Getting Started
            - enter the impure (default) dev shell with `nix develop` or `direnv`
            - initialize your uv project
            - afterwards, you may use the `uv2nix` dev shell, to make use of fully reproducible dependencies
          '';
        };

        latex = {
          path = ./latex;
          description = "Flake template for building LaTeX projects using pdflatex";
          welcomeText = ''
            # Getting Started
            - enter the dev shell with `nix develop` or `direnv`
            - create one or more `.tex` files
            - specify your package name & version in the `flake.nix`
          '';
        };

        monorepo = {
          path = ./monorepo;
          description = "Template for building multiple (polyglot) packages as part of a monorepo.";
          welcomeText = ''
            # Getting Started
            - define your package scope name in the `flake.nix`
            - start adding packages within the `./pkgs` directory
          '';
        };
      };
    };
}
