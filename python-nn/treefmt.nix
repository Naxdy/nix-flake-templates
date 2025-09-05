{ ... }:
{
  # nix
  programs.nixfmt.enable = true;

  # markdown, yaml, etc.
  programs.prettier = {
    enable = true;
    settings = {
      trailingComma = "all";
      semi = true;
      printWidth = 120;
      singleQuote = true;
      proseWrap = "always";
    };
  };

  programs.black.enable = true;

  programs.taplo.enable = true;

  programs.typos = {
    enable = true;
    includes = [
      "*.py1"
      "*.py"
      "*.nix"
    ];
  };
}
