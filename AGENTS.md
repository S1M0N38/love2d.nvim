# CLAUDE.md — love2d.nvim

> ## ⚠️ V3 REFACTOR IN PROGRESS
>
> This plugin is undergoing a **major refactor** (V3). The codebase is in a
> transitional state — some modules have been updated to the new architecture,
> others are still legacy V2 code. **Do not assume everything is consistent.**
>
> If something seems broken or contradictory, check [PROGRESS.md](PROGRESS.md)
> to see which steps have been completed.
>
> **This file is updated continuously during the refactor.** Always read it
> fresh at the start of a session — do not rely on cached knowledge from a
> previous session.

---

## Reference documents

These files guide the refactor. Read them when you need context on what's
changing and why.

| File | Purpose |
|------|---------|
| [V3.md](V3.md) | Design doc — the *what* and *why* of V3 changes |
| [V3-impl.md](V3-impl.md) | Implementation plan — the *how*, step by step |
| [PROGRESS.md](PROGRESS.md) | Checkbox tracker — which steps are done |
| [AGENTS.md](AGENTS.md) | **This file** — current state of the codebase |

When in doubt about the refactor: **V3-impl.md** is the source of truth for
what should happen. **PROGRESS.md** tells you where we actually are.

---

## Project Overview

`love2d.nvim` is a Neovim plugin that provides LSP integration, game execution
controls, and enhanced developer workflow for LÖVE 2D game projects.

### Target environment: bare-bone Neovim only

This plugin targets **stock Neovim** with no distribution or framework. It must
work perfectly with a minimal `init.lua` and Neovim's built-in plugin/package
management (`vim.pack`, `:packadd`, etc.).

**Do not** spend effort on compatibility with Neovim distributions or starter
templates (LazyVim, kickstart, NvChad, AstroNvim, MiniNvim, etc.). If a bug
only reproduces inside a distribution, it is that distribution's responsibility.

This principle applies to:
- Installation instructions (vim.pack and manual `opt` only — no lazy.nvim-specific `opts` tables)
- LSP configuration (use `vim.lsp.config` / `vim.lsp.enable` — no lspconfig wrapper)
- Testing (`nvim -l tests/minit.lua` — no test runner that depends on a plugin manager)
- Documentation (vimdoc and README should not mention distributions)

---

## V3 — Current State

> This section describes the codebase **as it is right now**, reflecting
> completed refactor steps. It grows as steps are completed.

### Refactor principles (from V3-impl.md)

1. **Source first, then tests** — Change source code, then port/write tests.
2. **One concern per step** — Each step is independently verifiable.
3. **Non-breaking first** — Pure additions before behavioral changes.
4. **No LÖVE binary in CI** — Tests requiring `love` skip with `pending()`.
5. **did_setup reset in tests** — `love2d.did_setup = false` in `before_each`.
6. **Real lua_ls in CI** — LSP tests use real lua-language-server, skip if missing.
7. **LSP unit tests** — Read `vim.lsp.config.lua_ls` after `setup()`, assert on settings.

### Development commands

> These may change as steps complete. Check PROGRESS.md for current state.

| Command | Notes |
|---------|-------|
| `make lint` | Stylua check (source + tests) |
| `make test` | Run test suite (target depends on completed steps) |
| `make format` | Auto-format with stylua |
| `make dev` | Open Neovim with sample LÖVE project |

### File structure (V3 target)

```
lua/love2d/
  init.lua          — Main module: setup(), run(), stop(), find_src_path()
  config.lua        — Options, LSP library injection, autocmds
  utils.lua         — Shared utilities (is_love2d_project, notify)
  types.lua         — [Step 2] LuaCATS type definitions (@meta)
  health.lua        — [Step 4] :checkhealth love2d support

compiler/
  love.lua          — [Step 5] Compiler plugin (makeprg + errorformat)

lsp/
  lua_ls.lua        — [Step 7] Static lua_ls settings (file-based LSP config)

love2d/library/     — LÖVE API definitions for LSP
luasocket/          — LuaSocket library definitions

tests/
  minit.lua         — [Step 10] mini.test runner
  love2d_spec.lua   — [Step 10] Unit tests (CI-safe)
  platform_spec.lua — [Step 10] Love binary tests (local-only, pending-based)
  lsp_spec.lua      — [Step 10] LSP unit + integration tests
  game/             — Sample LÖVE game for manual testing

after/queries/lua/
  injections.scm    — Treesitter injection for GLSL in LÖVE shaders

doc/love2d.txt      — Vimdoc help file
```

### V3 configuration options

| Option | Default | Description |
|--------|---------|-------------|
| `path_to_love_bin` | platform-specific | LÖVE executable path |
| `restart_on_save` | `false` | Auto-restart game on Lua file save |
| `debug_window_opts` | `nil` | Debug window configuration |
| `disable_default_definitions` | `false` | Skip LÖVE/LuaSocket library injection *(not yet implemented — Step 7)* |

### V3 architecture

**Setup flow (after Step 3)**
1. `love2d.setup(opts)` — guarded by `did_setup`, warns on double call
2. `require("love2d.config").setup(opts)` — merges defaults, detects project
3. If LÖVE project: `setup_lsp()` (injects libraries + configures lua_ls), create autocmds, set compiler

**LSP integration (current — Step 7 pending)**
- `config.lua` still uses imperative `setup_lsp()` with restart dance
- `setup_lsp()` merges runtime/library settings and restarts lua_ls
- After Step 7: static settings move to `lsp/lua_ls.lua`, only library injection stays in `config.lua`
- After Step 7: `disable_default_definitions` option gates library path injection

**Compiler plugin (after Step 5)**
- `compiler/love.lua` sets `makeprg` and `errorformat`
- Auto-activated via `vim.cmd.compiler("love")` when a LÖVE project is detected
- Replaces the old imperative `setup_makeprg_and_errorformat()` in config.lua

**Health checks (after Step 4)**
- `:checkhealth love2d` reports: did_setup, Neovim version, love binary, lua-language-server, treesitter parsers

### V3 testing (after Step 10)

- **Framework**: mini.test (via `tests/minit.lua`)
- **Unit tests** (`tests/love2d_spec.lua`): run in CI, no external deps
- **Platform tests** (`tests/platform_spec.lua`): need LÖVE binary, skip with `pending()`
- **LSP tests** (`tests/lsp_spec.lua`): unit tests read `vim.lsp.config.lua_ls`; integration tests need real lua-language-server

---

## V2 — Legacy (being replaced)

> ⚠️ This section describes the **old** V2 architecture. It is kept here for
> reference while the refactor is in progress. Items are removed once the
> corresponding V3 step is completed and verified.
>
> **If a V3 section above contradicts something here, the V3 section wins.**

### Legacy development commands

```
busted              — Run tests (Busted framework, requires nlua)
luacheck lua/       — Lint
stylua lua/ spec/   — Format
```

### Legacy file structure

```
lua/love2d/
  init.lua          — setup(), run(), stop(), find_src_path()
  config.lua        — LSP setup, project detection, autocmds, makeprg

spec/               — Busted test suite (deleted in Step 10)
  love2d_spec.lua
  lsp_spec.lua

.no neoconf.json    — Deleted in Step 6
.busted             — Deleted in Step 10
```

### Legacy testing

- Busted framework with `nlua`
- LSP tests marked as `pending` due to setup complexity
- Platform-specific binary paths for macOS/Linux

### Legacy configuration options

| Option | Notes |
|--------|-------|
| `setup_makeprg` | Removed in V3 — compiler is now always set for LÖVE projects |
| `setup_compiler` | Removed in V3 — compiler is now always set for LÖVE projects |
| `identify_love_projects` | Removed in V3 — project detection always runs, no toggle |
| `path_to_love_bin` | Unchanged in V3 |
| `restart_on_save` | Unchanged in V3 |
| `debug_window_opts` | Unchanged in V3 |

### Legacy architecture notes

- LSP configured imperatively in `config.lua` via `vim.lsp.config.lua_ls`
- `makeprg`/`errorformat` set via FileType autocmd in `config.lua`
- No `did_setup` guard (added in Step 3)
- No `types.lua`, `health.lua`, `compiler/love.lua`, `lsp/lua_ls.lua`
- Minimum Neovim version: 0.11 (bumped to 0.12 in Step 8)

---

## Skills

See `.agents/skills/` for task-specific instructions. Key skills:

| Skill | When to use |
|-------|-------------|
| `nvim-commit` | Creating conventional commits compatible with release-please |
| `nvim-doc` | Writing/updating `doc/love2d.txt` vimdoc |
| `nvim-help` | Looking up Neovim `:help` documentation |
| `nvim-plugin` | Neovim plugin development best practices |
| `nvim-test` | Running tests and diagnosing failures |

> ⚠️ Skills are updated in Step 14. Until then, `nvim-test` may still
> reference Busted patterns instead of mini.test.
