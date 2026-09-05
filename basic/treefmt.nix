{ ... }: {
  programs = {
    nixfmt.enable = true;

    typos = {
      enable = true;
      includes = [
        "*.md"
        "*.nix"
      ];
    };
  };
}
