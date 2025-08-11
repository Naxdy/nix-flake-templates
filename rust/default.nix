{
  pkgs,
  crane,
}:
let
  rustToolchain = pkgs.fenix.stable.withComponents [
    "cargo"
    "rustc"
    "rustfmt"
    "rust-std"
    "rust-analyzer"
    "clippy"
  ];

  # more info on https://crane.dev/API.html
  craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

  craneArgs = {
    pname = cargoToml.workspace.package.name or cargoToml.package.name;
    version = cargoToml.workspace.package.version or cargoToml.package.version;

    src = craneLib.cleanCargoSource ./.;

    strictDeps = true;

    # can add `nativeBuildInputs` or `buildInputs` here

    env = {
      # print backtrace on compilation failure
      RUST_BACKTRACE = "1";

      # treat warnings as errors
      RUSTFLAGS = "-Dwarnings";
      RUSTDOCFLAGS = "-Dwarnings";
    };
  };

  cargoArtifacts = craneLib.buildDepsOnly craneArgs;

  craneBuildArgs = craneArgs // {
    inherit cargoArtifacts;
  };
in
{
  package = craneLib.buildPackage (
    craneBuildArgs
    // {
      passthru = {
        tests = {
          test = craneLib.cargoTest craneBuildArgs;

          doc = craneLib.cargoDoc craneBuildArgs;

          clippy = craneLib.cargoClippy craneBuildArgs;
        };
      };
    }
  );

  docs = craneLib.cargoDoc (
    craneBuildArgs
    // {
      # used to disable `--no-deps`, which crane enables by default,
      # so we include all packages in the resulting docs, to have fully-functional
      # offline docs
      cargoDocExtraArgs = "";
    }
  );

  inherit rustToolchain cargoToml;
}
