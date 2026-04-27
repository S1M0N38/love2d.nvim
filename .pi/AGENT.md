# AGENT.md — love2d.nvim Pi Agent Instructions

You are an expert Lua/Neovim plugin developer working on `love2d.nvim`.

## Project Overview

`love2d.nvim` is a Neovim plugin that provides LSP integration, game execution controls, and enhanced development workflow for LÖVE 2D game projects.

## Development Commands

```bash
# Lint
luacheck lua/ spec/

# Format (uses .stylua.toml settings)
stylua lua/ spec/

# Run tests (requires nlua + busted)
busted

# Run prek hooks manually
prek run --all-files
```

## Architecture

### Core Modules

- `lua/love2d/init.lua` — Main module: setup(), run(), stop(), find_src_path()
- `lua/love2d/config.lua` — LSP setup, project detection, library path management

### Plugin Entry

- `plugin/love2d.lua` — Neovim plugin entry point (autoloaded)
- `after/queries/lua/injections.scm` — Treesitter injection for GLSL in LÖVE shaders

### Assets

- `love2d/library/` — LÖVE API definitions for lua_ls
- `luasocket/` — LuaSocket library definitions (git submodule)

### Tests

- `spec/love2d_spec.lua` — Game execution and job management tests
- `spec/lsp_spec.lua` — LSP configuration tests (pending)
- `tests/game/` — Sample LÖVE game for manual testing

### Docs & Config

- `doc/love2d.txt` — Vim help documentation
- `.luacheckrc` — Luacheck configuration (std=luajit, read_globals=vim)
- `.stylua.toml` — StyLua configuration (120 col, spaces, 2 indent)
- `prek.toml` — Prek pre-commit hooks configuration

## Key Patterns

### LSP Integration
- Uses `vim.lsp.config.lua_ls` (Nvim 0.11+ API)
- Merges with existing lua_ls settings via `vim.tbl_deep_extend`
- Adds LÖVE library paths to workspace.library
- Configures Lua 5.1 runtime and "love" global

### Project Detection
- Primary: `main.lua` file presence in current directory
- Secondary: scan `*.lua` files for `love.` function calls
- Controlled by `identify_love_projects` option (default: true)

### Job Management
- Single concurrent game instance (tracked via `job_id`)
- Optional debug window for stdout capture
- Auto-restart on save via `restart_on_save` option

## Configuration Options

- `path_to_love_bin` — Path to LÖVE executable
- `identify_love_projects` — Auto-detect LÖVE projects (default: true)
- `debug_window_opts` — Debug window configuration
- `restart_on_save` — Auto-restart game on Lua file save

## Code Style

- StyLua formatting: 120 column width, spaces, 2-space indent, AutoPreferDouble quotes
- Luacheck: LuaJIT std, vim as read_only global
- Conventional commits: `<type>(<scope>): <description>`

## Commit Guidelines

Use conventional commits enforced by prek hooks:
- `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

## Constraints

- Do not edit `CHANGELOG.md` manually (managed by release-please)
- Do not edit files in `love2d/library/` or `luasocket/` (vendored/submodule)
- Always run `luacheck` and `stylua --check` before committing
- Tests require `nlua` and `busted` to be installed
