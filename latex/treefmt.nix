{ ... }:
{
  programs.nixfmt.enable = true;

  programs.texfmt.enable = true;

  programs.typos = {
    enable = true;
    includes = [
      "*.nix"
      "*.tex"
    ];
  };
}
