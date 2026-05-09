# V3 — Implementation Plan

Detailed step-by-step plan for completing the V3 refactor.
Each step is atomic: source changes + verification, committed together.

---

## Guiding principles

1. **Source → Tests → Docs** — Complete all source changes first, then migrate tests, then rewrite docs.
2. **One concern per step** — Each step is independently verifiable.
3. **Non-breaking first** — Restructuring before behavioral changes.
4. **No LÖVE binary in CI** — Tests requiring `love` skip with `pending()`.
5. **did_setup reset in tests** — `love2d.did_setup = false` in `before_each`.
6. **Bare-bone Neovim only** — Every feature works on stock Neovim. No distribution effort.

---

## Completed steps (1–6)

These are done on the `v3` branch. Listed for reference.

| Step | Commit | What changed |
|------|--------|--------------|
| 1 | `chore: align StyLua config, add Makefile, drop prek.toml` | StyLua `call_parentheses = "Always"`, Makefile, deleted prek.toml |
| 2 | `feat(types): add separate LuaLS type definition file` | Created `lua/love2d/types.lua` |
| 3 | `feat(init): add did_setup guard to prevent double setup` | `did_setup` guard in init.lua |
| 4 | `feat(health): add :checkhealth love2d support` | Created `lua/love2d/health.lua` |
| 5 | `feat(compiler): add compiler/love.lua, replace imperative makeprg setup` | Compiler plugin + utils.lua |
| 6 | `ci: self-contained CI with Neovim types, no external actions` | Unified `.luarc.json`, self-contained CI |

---

## Step 7: Move submodules to `libraries/`

**Why**: Clean up the repo root. `libraries/love2d/` and `libraries/luasocket/` is self-documenting.

### Actions

1. Remove old submodules:
   ```bash
   git rm love2d
   git rm luasocket
   ```
2. Add submodules in new location:
   ```bash
   git submodule add https://github.com/LuaCATS/love2d.git libraries/love2d
   git submodule add https://github.com/LuaCATS/luasocket.git libraries/luasocket
   ```
3. Update `.gitmodules` paths (git handles this automatically)
4. Update `lua/love2d/config.lua`: change glob targets
   ```lua
   -- Before
   local libs = { "love2d", "luasocket" }
   -- After
   local libs = { "libraries/love2d", "libraries/luasocket" }
   ```
5. Verify: `make lint` passes, LSP still resolves library paths
6. Manual test: open `tests/game/`, hover on `love` → should show docs

### Commit

```
build(library): move type definition submodules to libraries/ directory
```

---

## Step 8: LSP verify + minimal cleanup

**Why**: Ensure `lsp/lua_ls.lua` static settings and `config.lua` dynamic injection work correctly together after submodule move. No deep refactor — just verify and clean.

### Actions

1. Verify `lsp/lua_ls.lua` has correct static settings:
   - `cmd = { "lua-language-server" }`
   - `runtime.version = "LuaJIT"`
   - `diagnostics.disable = { "duplicate-set-field" }`
   - `workspace.checkThirdParty = false`
2. Verify `config.lua` `setup_lsp_libraries()` correctly resolves `libraries/love2d` and `libraries/luasocket`
3. Verify `vim.lsp.enable("lua_ls")` is called only when a LÖVE project is detected
4. Clean up any dead code in `config.lua` (e.g., old commented-out vim.pack code)
5. Verify: `make lint` passes

### Commit

```
refactor(lsp): verify and clean up library path resolution
```

---

## Step 9: Internal-use convention for API

**Why**: `find_src_path()` and `is_love2d_project()` are used internally by the plugin but also available on the module table. Mark them as internal-use convention without removing them (no breaking change for users who may reference them).

### Actions

1. Update `lua/love2d/types.lua`: add `@private` annotation or `@internal` note to `find_src_path` and `is_love2d_project`
2. Update `lua/love2d/init.lua`: add a brief comment above these functions noting they're internal-use
3. Verify: `make lint` passes

### Commit

```
docs(api): mark find_src_path and is_love2d_project as internal-use
```

---

## Step 10: Neovim 0.12.2 version bump

**Why**: Breaking change aligned with V3.0. Allows use of newer Neovim APIs.

### Actions

1. Update `README.md`: Neovim ≥ 0.11 → ≥ 0.12.2
2. Update `lua/love2d/health.lua`: verify `has("nvim-0.12.2")` check
3. Update CI: pin to v0.12.2 Neovim release
4. Update `lua/love2d/types.lua` if version notes exist
5. Verify: `make lint` passes

### Commit

```
feat!: bump minimum Neovim version to 0.12.2
```

---

## Step 11: Migrate tests — busted + e2e → mini.test

**Why**: Unify testing under mini.test. The current e2e runners and busted specs are temporary. This step creates the final test suite against the stable V3 API.

### Test file plan

#### `tests/minit.lua` (new)

```lua
#!/usr/bin/env -S nvim -l
vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()
require("lazy.minit").setup({
  spec = {
    { dir = vim.uv.cwd(), opts = {} },
  },
})
```

#### `tests/love2d_spec.lua` (new — unit tests, no love binary)

CI-safe. Tests config, detection, setup guard, compiler autocmd, health.

| Describe block | Tests | Source |
|---|---|---|
| `find_src_path` | Finds main.lua in cwd, in specified path, returns nil for invalid/missing | `init.lua` |
| `setup` | Merges options with defaults, uses defaults with nil opts, warns on double setup | `init.lua` + `config.lua` |
| `is_love2d_project` | Detects via conf.lua, main.lua callbacks, main.lua modules; rejects regular Lua | `utils.lua` |
| `restart_on_save` | Creates/no autocmd based on option | `config.lua` |
| `compiler autocmd` | Compiler set for LÖVE projects | `config.lua` |
| `health check` | Reports correct status for setup/not-setup | `health.lua` |
| `error handling` | stop with no job, nil opts, run with empty path | `init.lua` |

Pattern:
```lua
---@module 'luassert'
local love2d = require("love2d")
---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function() end

local function reset_setup()
  love2d.did_setup = false
end
```

#### `tests/platform_spec.lua` (new — needs love binary, local-only)

Skipped in CI via `pending()`. Tests actual process management.

| Describe block | Tests | Source |
|---|---|---|
| `love2d platform` | Starts, stops, runs game, exit codes, wrong path | `init.lua` |
| `debug window` | Creates/doesn't create window | `init.lua` |
| `concurrent jobs` | Prevents multiple jobs | `init.lua` |

#### `tests/lsp_spec.lua` (new — LSP unit + integration)

Unit tests read `vim.lsp.config.lua_ls` after setup(). Integration tests need real lua_ls, skip with `pending()`.

| Describe block | Tests | Source |
|---|---|---|
| `LSP config resolution` | love2d + luasocket paths injected, static settings correct | `config.lua` + `lsp/lua_ls.lua` |
| `LSP integration` | Attaches lua_ls with correct settings, `love` not undefined | real lua_ls |

### Actions

1. Create `tests/minit.lua`
2. Create `tests/love2d_spec.lua` (unit tests)
3. Create `tests/platform_spec.lua` (love binary tests, pending-based)
4. Create `tests/lsp_spec.lua` (unit + integration)
5. Delete `spec/` directory (`love2d_spec.lua`, `lsp_spec.lua`, `health_spec.lua`)
6. Delete `tests/e2e_game.lua` and `tests/e2e_bad_game.lua`
7. Update `Makefile`:
   - Change test targets from `cd tests/game && nvim ...` to `nvim -l tests/minit.lua --minitest`
   - Update lint/format to use `tests/` instead of `spec/`
8. Verify: `make test` passes all unit tests

### Commit

```
test!: migrate from busted/e2e to mini.test
```

---

## Step 12: CONTRIBUTING.md

**Why**: Onboarding docs for contributors.

### Sections

1. **Getting Started** — Clone, submodules, run `make check`
2. **Prerequisites** — Neovim ≥ 0.12.2, StyLua, LÖVE, lua-language-server
3. **Make Targets** — `make test`, `make lint`, `make format`, `make check`, `make dev`
4. **Architecture** — Module overview (init.lua, config.lua, utils.lua, types.lua, health.lua, compiler/love.lua, lsp/lua_ls.lua)
5. **Code Style** — StyLua (120 col, spaces, 2 indent, `call_parentheses = "Always"`)
6. **Commit Convention** — Conventional commits (release-please parses changelog)
7. **Constraints** — Don't edit vendored libs in `libraries/`, don't edit CHANGELOG.md

### Commit

```
docs: add CONTRIBUTING.md
```

---

## Step 13: Rewrite `doc/love2d.txt`

**Why**: The current vimdoc is outdated (references removed options, old LSP approach, old installation). Rewrite from scratch against the final V3 API.

### Sections

1. **INTRODUCTION** — What the plugin does
2. **SETUP** — Installation (lazy.nvim) + `setup()` options
3. **COMMANDS** — `:LoveRun`, `:LoveStop`
4. **LSP** — How LSP integration works (file-based config, submodule libraries)
5. **COMPILER** — `:make` quickfix integration + conf.lua errorhandler pattern
6. **GLSL** — Treesitter injection for inline shaders
7. **HEALTH** — `:checkhealth love2d`
8. **API** — `setup()`, `run()`, `stop()` (internal functions noted)

### Key changes from current vimdoc

- Remove `setup_makeprg` and `identify_love_projects` options
- Document only 3 config options: `path_to_love_bin`, `restart_on_save`, `debug_window_opts`
- Add `:checkhealth love2d` section
- Add compiler/quickfix section with conf.lua errorhandler pattern
- Update LSP section for file-based config
- Keep lazy.nvim installation example

### Commit

```
docs(love2d.txt): rewrite vimdoc for V3
```

---

## Step 14: Update README.md

**Why**: README still references Neovim ≥ 0.11 and doesn't mention V3 changes.

### Actions

1. Update version badge/note: V3.0.0, Neovim ≥ 0.12.2
2. Update requirements section
3. Update installation example (remove `version = "2.*"`)
4. Update opts table to show only V3 options
5. Verify: manual read-through

### Commit

```
docs(readme): update for V3
```

---

## Step 15: Update AGENTS.md

**Why**: Final update to reflect the complete V3 state.

### Actions

- Update **V3 — Current State** to describe the final architecture
- Remove **V2 — Legacy** section entirely (V3 is done)
- Update **Development Commands** for mini.test
- Update **File Structure** for `libraries/` and mini.test
- Update **V3 Configuration Options** to final set
- Update **V3 Testing** for mini.test
- Remove any V3 transition notes

### Commit

```
docs(agents): update AGENTS.md for completed V3
```

---

## Step 16: Add test job to CI

**Why**: After mini.test migration, run tests in CI.

### Actions

Add `test` job to `.github/workflows/ci.yml`:

```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with:
        submodules: true
    - name: Install Neovim
      run: |
        curl -L https://github.com/neovim/neovim/releases/download/v0.12.2/nvim-linux-x86_64.tar.gz | tar xz -C "$HOME"
        echo "$HOME/nvim-linux-x86_64/bin" >> $GITHUB_PATH
    - name: Run tests
      run: nvim -l tests/minit.lua --minitest
```

Platform tests (love binary) skip via `pending()`. LSP integration tests skip if no lua_ls.

### Commit

```
ci: add mini.test job to CI
```

---

## Step 17: Update skills

**Why**: Skills should reflect the final test infrastructure.

### Actions

1. Update `.agents/skills/nvim-test/SKILL.md`: mini.test, tests/minit.lua, `make test`, `pending()` pattern
2. Update `.agents/skills/nvim-plugin/references/TESTS.md`: mini.test patterns

### Commit

```
chore(skills): update nvim-test and TESTS.md for mini.test
```

---

## Summary: commit sequence

| Step | Commit | Breaking? | Status |
|------|--------|-----------|--------|
| 1 | `chore: align StyLua config, add Makefile, drop prek.toml` | No | ✅ Done |
| 2 | `feat(types): add separate LuaLS type definition file` | No | ✅ Done |
| 3 | `feat(init): add did_setup guard to prevent double setup` | No | ✅ Done |
| 4 | `feat(health): add :checkhealth love2d support` | No | ✅ Done |
| 5 | `feat(compiler): add compiler/love.lua, replace imperative makeprg setup` | No | ✅ Done |
| 6 | `ci: self-contained CI with Neovim types, no external actions` | No | ✅ Done |
| 7 | `build(library): move type definition submodules to libraries/` + `fix(lsp): add cmd to lua_ls config` | No | ✅ Done |
| 8 | `refactor(lsp): verify and clean up library path resolution` | No | 🔲 Remaining |
| 9 | `docs(api): mark find_src_path and is_love2d_project as internal-use` | No | 🔲 Remaining |
| 10 | `feat!: bump minimum Neovim version to 0.12.2` | **Yes** | 🔲 Remaining |
| 11 | `test!: migrate from busted/e2e to mini.test` | **Yes** | 🔲 Remaining |
| 12 | `docs: add CONTRIBUTING.md` | No | 🔲 Remaining |
| 13 | `docs(love2d.txt): rewrite vimdoc for V3` | No | 🔲 Remaining |
| 14 | `docs(readme): update for V3` | No | 🔲 Remaining |
| 15 | `docs(agents): update AGENTS.md for completed V3` | No | 🔲 Remaining |
| 16 | `ci: add mini.test job to CI` | No | 🔲 Remaining |
| 17 | `chore(skills): update nvim-test and TESTS.md for mini.test` | No | 🔲 Remaining |
