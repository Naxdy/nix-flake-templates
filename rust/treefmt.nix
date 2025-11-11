{ pname }:
{ pkgs, ... }:
let
  inherit (pkgs.${pname}.passthru) rustToolchain cargoToml;
in
{
  # rust
  programs.rustfmt = {
    enable = true;
    package = rustToolchain;
    edition = cargoToml.workspace.package.edition or cargoToml.package.edition or "2024";
  };

  # nix
  programs.nixfmt.enable = true;

  # toml
  programs.taplo.enable = true;

  # markdown, yaml, etc.
  programs.prettier = {
    enable = true;
    settings = {
      trailingComma = "all";
      semi = true;
      printWidth = 120;
      singleQuote = true;
    };
  };

  programs.typos = {
    enable = true;
    includes = [
      "*.md"
      "*.nix"
      "*.rs"
    ];
  };
}
