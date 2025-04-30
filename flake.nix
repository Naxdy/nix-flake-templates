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
            - enter a dev shell with `nix develop` or `direnv`
            - run `cargo init` to initialize a rust project
            - get rusty
          '';
        };
      };
    };
}
