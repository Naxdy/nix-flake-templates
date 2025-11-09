{ ... }:
{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  programs.typos = {
    enable = true;
    includes = [
      "*.js"
      "*.jsx"
      "*.lua"
      "*.md"
      "*.nix"
      "*.rs"
      "*.svelte"
      "*.ts"
      "*.tsx"
    ];
  };

  programs.prettier = {
    enable = true;
    settings = {
      printWidth = 120;
      semi = true;
      singleQuote = true;
      trailingComma = "all";
      proseWrap = "always";
      includes = [
        "*.cjs"
        "*.css"
        "*.html"
        "*.js"
        "*.json"
        "*.json5"
        "*.jsx"
        "*.md"
        "*.mdx"
        "*.mjs"
        "*.scss"
        "*.svelte"
        "*.ts"
        "*.tsx"
        "*.vue"
        "*.yaml"
        "*.yml"
      ];
    };
  };
}
