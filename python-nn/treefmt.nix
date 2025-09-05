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
    };
  };

  programs.black.enable = true;

  programs.typos = {
    enable = true;
    includes = [
      "*.py1"
      "*.py"
      "*.nix"
    ];
  };
}
