{
  lib,
  pnpm,
  nodejs,
  stdenv,
}:
let
  packageJSON = builtins.fromJSON (builtins.readFile ./package.json);
in
stdenv.mkDerivation (finalAttrs: {
  pname = packageJSON.name;
  inherit (packageJSON) version;

  src = builtins.path {
    path = ./.;
    name = "source";
  };

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = lib.fakeHash;
  };

  passthru = {
    inherit (finalAttrs) pnpmDeps;
    inherit packageJSON;

    tests = {
      # TODO: put eslint, typescript, etc. here
    };
  };

  nativeBuildInputs = [
    pnpm
    nodejs
  ];

  buildInputs = [
    pnpm.configHook
  ];

  # TODO: buildPhase, installPhase

  fixupPhase = ''
    patchShebangs $out/
  '';
})
