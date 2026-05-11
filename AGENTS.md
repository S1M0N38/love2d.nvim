# AGENTS.md — love2d.nvim

Neovim plugin providing LSP integration, game execution, and developer workflow for LÖVE 2D projects.

**Stock Neovim only** — no effort on distributions (LazyVim, NvChad, etc.).

## File structure

```
lua/love2d/
  init.lua          setup(), guards double-call
  config.lua        Options (path_to_love_bin, output)
  utils.lua         Project detection (walks up from CWD)
  types.lua         LuaCATS type definitions (@meta, not loaded at runtime)
  health.lua        :checkhealth love2d
  job.lua           Process lifecycle (run, watch, stop)
  output.lua        Floating output panel + inline diagnostics
  events.lua        Fires EnterLove2DProject / LeaveLove2DProject
  lsp.lua           Dynamic lua_ls config on project enter/leave
  autocmd.lua       Enter/Leave handlers (job state, notifications)

compiler/love.lua   Compiler plugin (makeprg + errorformat)
lsp/lua_ls.lua      Static base lua_ls config (cmd)
plugin/love2d.lua   :Love command with subcommands
libraries/          LÖVE + LuaSocket type definitions (git submodules)
after/              Treesitter GLSL injections + output syntax
tests/              mini.test suite (*_spec.lua) + demo-game fixture
doc/love2d.txt      Vimdoc
```

## Commands

`:Love run` / `watch` / `stop` / `info` / `output`

## Config

| Option | Default | Description |
|--------|---------|-------------|
| `path_to_love_bin` | `"love"` | Path to LÖVE binary |
| `output` | `nil` | `false` disables auto-open; table overrides floating window config |

## Development commands

| Command | Notes |
|---------|-------|
| `make format` | stylua |
| `make lint` | lua-language-server --check |
| `make test` | mini.test suite |
| `make test-one MODULE=config` | Single test file |
| `make check` | lint + test |
| `make dev` | Open Neovim with sample LÖVE project |
| `make clean` | Remove `.repro` and `.tests` |

## Testing

- **Framework**: mini.test via `tests/minit.lua`
- Reset `love2d.did_setup = false` in `before_each`
- Tests needing the `love` binary use `pending()`
