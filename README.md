<h1 align="center">✨ My Awesome Plugin ✨</h1>

<p align="center">
  <a href="https://github.com/S1M0N38/my-awesome-plugin.nvim/actions/workflows/test.yml">
    <img alt="Tests" src="https://img.shields.io/github/actions/workflow/status/S1M0N38/my-awesome-plugin.nvim/test.yml?style=for-the-badge&label=Tests"/>
  </a>
  <a href="https://github.com/S1M0N38/my-awesome-plugin.nvim/actions/workflows/docs.yml">
    <img alt="Docs" src="https://img.shields.io/github/actions/workflow/status/S1M0N38/my-awesome-plugin.nvim/docs.yml?style=for-the-badge&label=Docs"/>
  </a>
  <a href="https://github.com/S1M0N38/my-awesome-plugin.nvim/releases">
    <img alt="Release" src="https://img.shields.io/github/v/release/S1M0N38/my-awesome-plugin.nvim?style=for-the-badge"/>
  </a>
</p>

______________________________________________________________________

A simple way to kickstart your Neovim plugin development like a pro with:

- [Plugin Structure](#-plugin-structure)
- [Tests](#-tests)
- [Docs Generation](#-docs-generation)
- [Linting and Formatting](#-linting-and-formatting)
- [Deployment](#-deployment)

**Usage**:

1. On the top right of this page, click on `Use this template` > `Create a new repository`.
1. Clone your new repo and `cd` into it.
1. Kickstart with

```sh
make init name=the_name_of_your_plugin
```

Then, modify the `README.md`, `.github/workflows/release.yml`, and `LICENSE` files to your liking.

## 📁 Plugin Structure

- `plugin/my_awesome_plugin.lua` - *the main file, the one loaded by the plugin manager*

- `lua/my_awesome_plugin/`

  - `init.lua` - *the main file of the plugin, the one loaded by `plugin/my_awesome_plugin.lua`*
  - `math.lua` - *an example module, here we define simple math functions*
  - `config.lua` - *store plugin default options and extend them with user's ones*

- `tests/my_awesome_plugin/`

  - `my_awesome_plugin_spec.lua` - *plugin tests. Add other `*_spec.lua` files here for further testing*

- `scripts/`

  - `docs.lua` - *Lua script to auto-generate `doc/my_awesome_plugin.txt` docs file from code annotations*
  - `minimal_init.lua` - *start Neovim instances with minimal plugin configuration. Used in `Makefile`*

- `Makefile` - *script for launching **tests**, **linting**, and docs generation*

The other files are not important and will be mentioned in the following sections.

## 🧪 Tests

Tests are run using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim), a Lua library for Neovim plugin development. [Here](https://github.com/nvim-lua/plenary.nvim/blob/master/TESTS_README.md) is how to write tests using plenary.

To run the tests on your local machine for local development, you can:

- Have the plenary plugin in your Neovim configuration and use `:PlenaryBustedDirectory tests`.
- Have the plenary repo cloned in the same directory as the my_awesome_plugin repo and use `make test`.

When running tests on CI, plenary.nvim is cloned, and the tests are run using `make test`.

## 📚 Docs Generation

In the Vim/Neovim world, it's customary to provide documentation in the Vim style, a txt file with tags and sections that can be navigated using the `:help` command.
In Lua, we can add annotations to our code, i.e., comments starting with `---`, so that we can have the full signature of functions and modules for LSP sorcery. [Here](https://github.com/tjdevries/tree-sitter-lua/blob/master/HOWTO.md) is how to write code annotations.

Lua code annotations can be used to generate the Vim style docs using the `docgen` module from [tree-sitter-lua](https://github.com/tjdevries/tree-sitter-lua). This is an alternative tree-sitter parser, so it's not installed by the tree-sitter plugin. To generate the docs locally, you must clone the tree-sitter-lua repo in the same directory as the my_awesome_plugin repo and use `make docs`.

When running docs generation on CI, tree-sitter-lua is cloned, and the docs are generated using `make docs`.

## 🧹 Linting and Formatting

Linting highlights code that is syntactically correct but may not be the best practice and can lead to bugs or errors.
Formatting is the process of transforming code into a standardized format that makes it easier to read and understand.

- [Luacheck](https://github.com/mpeterv/luacheck) is run by `make lint` using the configuration in the `.luacheckrc` file.
- In CI, [Stylua](https://github.com/JohnnyMorganz/StyLua) is run after linting using the configuration in the `.stylua.toml` file.

## 🚀 Deployment

[Tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging) are how Git marks milestones in the commit history of a repository.
Tags can be used to trigger releases, i.e., publish a specific version of the plugin on GitHub and LuaRocks.

- A new release on GitHub is automatically created when a new tag is pushed.
- A new release on LuaRocks is automatically created when a new tag is pushed. It requires adding `LUAROCKS_API_KEY` as a secret in the repo settings.

## 👏 Acknowledgments

Neovim is growing a nice ecosystem, but some parts of plugin development are sometimes obscure. This template is an attempt to put together best practices by copying:

- [ellisonleao/nvim-plugin-template](https://github.com/ellisonleao/nvim-plugin-template) - *Plugin Structure*
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - *Tests, lint, docs generation*

I highly suggest [this video tutorial](https://youtu.be/n4Lp4cV8YR0?si=lHlxQBNvbTcXPhVY) by [TJ DeVries](https://github.com/tjdevries), a walkthrough of the Neovim plugin development process.
