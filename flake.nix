{
  description = "Flake templates that make sense";

  outputs =
    { self }:
    {
      templates = {
        rust = {
          path = ./rust;
          description = "Starter flake for rust projects, using `crane` and `fenix`, as well as `treefmt` for project-wide formatting.";
          welcomeText = ''
            # Getting Started
            - run `nix develop .#toolchainOnly --command cargo init` to initialize a rust project
            - enter a dev shell with `nix develop` or `direnv`
            - get rusty
          '';
        };

        pnpm = {
          path = ./pnpm;
          description = "Starter flake for nodejs projects using `pnpm`, as well as `treefmt` for project-wide formatting.";
          welcomeText = ''
            # Getting Started
            - enter a dev shell with `nix develop` or `direnv`
            - initialize your pnpm project
          '';
        };
      };
    };
}
