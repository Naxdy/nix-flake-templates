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

  programs.typos = {
    enable = true;
    includes = [
      "*.js"
      "*.ts"
      "*.jsx"
      "*.tsx"
      "*.svelte"
      "*.nix"
    ];
  };
}
