# AGENTS.md — love2d.nvim

> ## ⚠️ V3 REFACTOR IN PROGRESS
>
> This plugin is undergoing a **major refactor** (V3). The codebase is in a
> transitional state — some modules reflect the new architecture, others are
> still interim. **Do not assume everything is consistent.**
>
> Check [PROGRESS.md](PROGRESS.md) to see which steps have been completed.
>
> **This file is updated continuously during the refactor.** Always read it
> fresh at the start of a session — do not rely on cached knowledge.
>
> The V3 work is on a **dedicated branch** (`v3`) with a **draft PR #22** on
> GitHub. All V3 commits should target that branch, not `main`.

---

## Reference documents

| File | Purpose |
|------|---------|
| [V3.md](V3.md) | Design doc — the *what* and *why* of V3 changes |
| [V3-impl.md](V3-impl.md) | Implementation plan — the *how*, step by step |
| [PROGRESS.md](PROGRESS.md) | Checkbox tracker — which steps are done |
| [AGENTS.md](AGENTS.md) | **This file** — current state of the codebase |

When in doubt: **V3-impl.md** is the source of truth for what should happen.
**PROGRESS.md** tells you where we actually are.

---

## Project Overview

`love2d.nvim` is a Neovim plugin that provides LSP integration, game execution
controls, and enhanced developer workflow for LÖVE 2D game projects.

**Philosophy**: Focused but complete. LSP + run/stop + compiler + project
detection + health checks. No scope creep beyond this.

**Audience**: Both LÖVE developers new to Neovim AND Neovim users trying LÖVE.
Zero-config experience after `setup()` is the goal.

### Target environment: bare-bone Neovim only

This plugin targets **stock Neovim** with no distribution or framework. It must
work perfectly with a minimal `init.lua` and Neovim's built-in plugin/package
management.

**Do not** spend effort on compatibility with Neovim distributions or starter
templates (LazyVim, kickstart, NvChad, etc.). If a bug only reproduces inside a
distribution, it is that distribution's responsibility.

---

## Development commands

| Command | Notes |
|---------|-------|
| `make lint` | Stylua check (currently `lua/ spec/`) |
| `make test` | Run e2e tests (temporary, will become mini.test) |
| `make format` | Auto-format with stylua |
| `make check` | lint + test |
| `make dev` | Open Neovim with sample LÖVE project |
| `make clean` | Remove `.repro` directories |

---

## V3 — Current State

> This section describes the codebase **as it is right now**, reflecting
> completed refactor steps.

### Refactor principles

1. **Source first, then tests** — Source changes before test migration.
2. **One concern per step** — Each step is independently verifiable.
3. **Non-breaking first** — Pure additions before behavioral changes.
4. **No LÖVE binary in CI** — Tests requiring `love` skip with `pending()`.
5. **did_setup reset in tests** — `love2d.did_setup = false` in `before_each`.
6. **Bare-bone Neovim only** — Every feature works on stock Neovim.

### File structure (current — mid-refactor)

```
lua/love2d/
  init.lua          — Main module: setup(), run(), stop(), find_src_path()
  config.lua        — Options, LSP library injection, autocmds
  utils.lua         — Shared utilities (is_love2d_project, notify)
  types.lua         — LuaCATS type definitions (@meta)
  health.lua        — :checkhealth love2d support

compiler/
  love.lua          — Compiler plugin (makeprg + errorformat)

lsp/
  lua_ls.lua        — Static lua_ls settings (file-based LSP config)

plugin/
  love2d.lua        — User commands (:LoveRun, :LoveStop)

love2d/             — LÖVE API type definitions (git submodule) → will move to libraries/
luasocket/          — LuaSocket type definitions (git submodule) → will move to libraries/

after/queries/lua/
  injections.scm    — Treesitter injection for GLSL in LÖVE shaders

spec/               — Busted test suite (temporary, will be deleted)
  love2d_spec.lua
  lsp_spec.lua
  health_spec.lua

tests/
  e2e_game.lua      — Custom e2e runner (temporary, will be deleted)
  e2e_bad_game.lua  — Custom e2e runner (temporary, will be deleted)
  game/             — Sample LÖVE game for testing
  bad-game/         — Broken LÖVE game for error testing

doc/love2d.txt      — Vimdoc (outdated, will be rewritten)
```

### File structure (V3 target — after all steps complete)

```
lua/love2d/
  init.lua          — Main module: setup(), run(), stop()
  config.lua        — Options, LSP library injection, autocmds
  utils.lua         — Shared utilities (is_love2d_project, notify)
  types.lua         — LuaCATS type definitions (@meta)
  health.lua        — :checkhealth love2d support

compiler/
  love.lua          — Compiler plugin (makeprg + errorformat)

lsp/
  lua_ls.lua        — Static lua_ls settings (file-based LSP config)

plugin/
  love2d.lua        — User commands (:LoveRun, :LoveStop)

libraries/
  love2d/           — LÖVE type definitions (git submodule)
  luasocket/        — LuaSocket type definitions (git submodule)

after/queries/lua/
  injections.scm    — Treesitter injection for GLSL in LÖVE shaders

tests/
  minit.lua         — mini.test runner
  love2d_spec.lua   — Unit tests (CI-safe)
  platform_spec.lua — Love binary tests (local-only, pending-based)
  lsp_spec.lua      — LSP unit + integration tests
  game/             — Sample LÖVE game for testing
  bad-game/         — Broken LÖVE game for error testing

doc/love2d.txt      — Vimdoc (rewritten for V3)
```

### V3 configuration options

| Option | Default | Description |
|--------|---------|-------------|
| `path_to_love_bin` | `"love"` | Path to the LÖVE executable |
| `restart_on_save` | `false` | Auto-restart game on Lua file save |
| `debug_window_opts` | `nil` | Debug window configuration |

### V3 architecture

**Setup flow**
1. `love2d.setup(opts)` — guarded by `did_setup`, warns on double call
2. `require("love2d.config").setup(opts)` — merges defaults, detects project
3. If LÖVE project: `setup_lsp_libraries()` (injects submodule paths into lua_ls), `vim.lsp.enable("lua_ls")`, create autocmds, set compiler

**LSP integration**
- `lsp/lua_ls.lua` provides static settings (LuaJIT runtime, diagnostics, checkThirdParty)
- `config.lua` resolves submodule paths (`libraries/love2d/`, `libraries/luasocket/`) from runtimepath and injects into lua_ls `workspace.library`
- Type definitions ship as git submodules (LuaCATS/love2d, LuaCATS/luasocket)
- Users override via `after/lsp/lua_ls.lua` (Neovim's built-in config chain)

**Compiler plugin**
- `compiler/love.lua` sets `makeprg` and `errorformat`
- Auto-activated via `vim.cmd.compiler("love")` when a LÖVE project is detected
- `:make` runs the game, errors parse into quickfix

**Health checks**
- `:checkhealth love2d` reports: did_setup, Neovim version, love binary, lua-language-server, treesitter parsers

**Public API**
- `setup(opts)`, `run(path)`, `stop()` — documented, stable
- `find_src_path(path)`, `is_love2d_project()` — internal-use convention, available but not guaranteed stable

**User commands**
- `:LoveRun [path]` — run LÖVE project (auto-detects path if omitted)
- `:LoveStop` — stop running project

**No default keymaps** — users define their own.

### V3 testing (target — after mini.test migration)

- **Framework**: mini.test (via `tests/minit.lua` using lazy.minit)
- **Unit tests** (`tests/love2d_spec.lua`): run in CI, no external deps
- **Platform tests** (`tests/platform_spec.lua`): need LÖVE binary, skip with `pending()`
- **LSP tests** (`tests/lsp_spec.lua`): unit tests read `vim.lsp.config.lua_ls`; integration tests need real lua_ls

---

## Skills

See `.agents/skills/` for task-specific instructions.

| Skill | When to use |
|-------|-------------|
| `nvim-commit` | Creating conventional commits compatible with release-please |
| `nvim-doc` | Writing/updating `doc/love2d.txt` vimdoc |
| `nvim-help` | Looking up Neovim `:help` documentation |
| `nvim-plugin` | Neovim plugin development best practices |
| `nvim-test` | Running tests and diagnosing failures |

> ⚠️ Skills will be updated for mini.test in Step 17.
