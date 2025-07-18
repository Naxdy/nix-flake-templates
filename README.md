# Nix Flake Templates

Welcome to my personal Nix flake template collection. This project provides templates for a couple different programming
languages / frameworks, coupled together with Nix flake & build support, as well as `treefmt` for tree-wide (and
language-agnostic) formatting.

Run the following command to see all available templates:

```shell
nix flake show git+https://git.naxdy.org/NaxdyOrg/nix-flake-templates.git
```

If you want to initialize a new project using one of the templates, run a command like the following:

```shell
# This will initialize a new project using the `rust` template.
nix flake show git+https://git.naxdy.org/NaxdyOrg/nix-flake-templates.git#rust
```

## Contributing

> [!NOTE]
>
> The repository's source of truth is over at my
> [personal git instance](https://git.naxdy.org/NaxdyOrg/nix-flake-templates). If you submit a PR that I choose to
> accept, your PR on GitHub will be closed, and your commit cherry-picked into the repository.

This is my personal template collection, so it is _highly_ unlikely that I will accept feature or style-based PRs. I
will, however, accept bugfixes and "general" improvements (if unsure, ask).

## License

The entire project is licensed under the [CC0](./LICENSE). In short, you can use, modify, and redistribute everything in
here, without needing to give credit. If you decide to contribute, you agree to submit your contributions under the same
license unless stated otherwise.
