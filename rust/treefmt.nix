{ rustToolchain, cargoToml }:
{ pkgs, ... }:
{
  programs.rustfmt = {
    enable = true;
    package = rustToolchain;
    edition = cargoToml.workspace.package.edition or cargoToml.package.edition;
  };
  programs.nixfmt.enable = true;
  programs.typos = {
    enable = true;
    includes = [
      "*.rs"
    ];
  };
}
