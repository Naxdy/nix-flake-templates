{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      treefmt-nix,
    }:
    let
      supportedSystems = [ "x86_64-linux" ];

      pyproject = builtins.fromTOML (builtins.readFile ./pyproject.toml);

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
            };

            python = builtins.throw "Missing python version in flake.nix; recommended to pin to a fixed version, e.g. pkgs.python312";

            workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

            overlay = workspace.mkPyprojectOverlay {
              sourcePreference = "wheel";
            };

            # nvidia deps have a lot of shared objects that depend on each other,
            # however they will be invisible to nix and autoPatchelfHook, so we need
            # to mask them here
            ignoreMissingDepsOverlay =
              let
                packages = [
                  "nvidia-cufile-cu12"
                  "nvidia-cusolver-cu12"
                  "nvidia-cusparse-cu12"
                  "nvidia-nvshmem-cu12"
                  "torch"
                ];

                missingDeps = [
                  "libcublas.so.12"
                  "libcublasLt.so.12"
                  "libcuda.so.1"
                  "libcudart.so.12"
                  "libcudnn.so.9"
                  "libcufft.so.11"
                  "libcufile.so.0"
                  "libcupti.so.12"
                  "libcurand.so.10"
                  "libcusolver.so.11"
                  "libcusparse.so.12"
                  "libcusparseLt.so.0"
                  "libfabric.so.1"
                  "libibverbs.so.1"
                  "libmlx5.so.1"
                  "libmpi.so.40"
                  "libnccl.so.2"
                  "libnvJitLink.so.12"
                  "libnvrtc.so.12"
                  "liboshmem.so.40"
                  "libpmix.so.2"
                  "librdmacm.so.1"
                  "libucp.so.0"
                  "libucs.so.0"
                ];
              in
              final: prev:
              (builtins.listToAttrs (
                map (name: {
                  inherit name;
                  value = prev.${name}.overrideAttrs (old: {
                    autoPatchelfIgnoreMissingDeps = missingDeps;
                  });
                }) packages
              ));

            pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
              pkgs.lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                ignoreMissingDepsOverlay
                overlay
              ]
            );

            treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

            treefmt = treefmtEval.config.build.wrapper;
          in
          f {
            inherit
              ignoreMissingDepsOverlay
              overlay
              pkgs
              python
              pythonSet
              system
              treefmt
              treefmtEval
              workspace
              ;
          }
        );
    in
    {
      formatter = forEachSupportedSystem ({ treefmt, ... }: treefmt);

      devShells = forEachSupportedSystem (
        {
          ignoreMissingDepsOverlay,
          pkgs,
          python,
          pythonSet,
          system,
          treefmt,
          workspace,
          ...
        }:
        {
          default = self.devShells.${system}.impure;

          # shell for managing uv / python deps imperatively
          impure = pkgs.mkShell {
            packages = [
              pkgs.uv
              python
              treefmt
            ];

            env = {
              # Let Nix manage Python
              UV_PYTHON_DOWNLOADS = "never";
              UV_PYTHON = python.interpreter;

              # Python libraries often load native shared objects using dlopen(3).
              # Setting LD_LIBRARY_PATH makes the dynamic library loader aware of libraries without using RPATH for lookup.
              LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
            };

            shellHook = ''
              # Needed for Pytorch to find cuda libraries
              export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH

              # Undo dependency propagation by nixpkgs.
              unset PYTHONPATH

              if [ -f ./.venv/bin/activate ]; then
                source ./.venv/bin/activate
              fi
            '';
          };

          # fully declarative development shell with all deps managed by nix
          uv2nix =
            let
              editableOverlay = workspace.mkEditablePyprojectOverlay {
                root = "$REPO_ROOT";
              };

              editablePythonSet = pythonSet.overrideScope (
                pkgs.lib.composeManyExtensions [
                  editableOverlay
                  ignoreMissingDepsOverlay
                  (final: prev: {
                    ${pyproject.project.name} = prev.${pyproject.project.name}.overrideAttrs (old: {
                      src = pkgs.lib.fileset.toSource {
                        root = old.src;
                        fileset = pkgs.lib.fileset.unions [
                          (old.src + "/pyproject.toml")
                        ];
                      };

                      nativeBuildInputs = old.nativeBuildInputs ++ (final.resolveBuildSystem { editables = [ ]; });
                    });
                  })
                ]
              );

              virtualenv = editablePythonSet.mkVirtualEnv "${pyproject.project.name}-dev-env" workspace.deps.all;
            in
            pkgs.mkShell {
              packages = [
                pkgs.uv
                treefmt
                virtualenv
              ];

              env = {
                # Let Nix manage all things Python
                UV_NO_SYNC = "1";
                UV_PYTHON = python.interpreter;
                UV_PYTHON_DOWNLOADS = "never";
              };

              shellHook = ''
                # Undo dependency propagation by nixpkgs.
                unset PYTHONPATH

                # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
                export REPO_ROOT=$(git rev-parse --show-toplevel)

                # Needed for Pytorch to find cuda libraries
                export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH
              '';
            };
        }
      );

      checks = forEachSupportedSystem (
        { treefmtEval, system, ... }:
        {
          treefmt = treefmtEval.config.build.check self;

          uv2nixShell = self.devShells.${system}.uv2nix;
        }
      );
    };
}
