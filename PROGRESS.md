# V3 Implementation Progress

Tracking implementation of the [V3 plan](V3-impl.md).

---

## Completed (Steps 1–6)

### Step 1: StyLua config + drop prek.toml + Makefile

- [x] Update `.stylua.toml`: `call_parentheses = "Always"`
- [x] Run `stylua lua/ spec/` to reformat
- [x] Delete `prek.toml`
- [x] Create `Makefile` (targets: test, lint, format, check, dev, clean)
- [x] Verify: `make lint` passes

Commit: `chore: align StyLua config, add Makefile, drop prek.toml`

---

### Step 2: `lua/love2d/types.lua`

- [x] Create `lua/love2d/types.lua` with `@meta _` header
- [x] Define types: `Love2D.Job`, `Love2D.Config`
- [x] Update `lua/love2d/init.lua`: replace inline type annotations
- [x] Verify: `make lint` passes

Commit: `feat(types): add separate LuaLS type definition file`

---

### Step 3: `did_setup` guard in init.lua

- [x] Add `love2d.did_setup = false` to init.lua
- [x] Update `love2d.setup()` with guard + warning
- [x] Patch `spec/love2d_spec.lua` with `reset_setup()` in `before_each`
- [x] Verify: `make lint` passes

Commit: `feat(init): add did_setup guard to prevent double setup`

---

### Step 4: `lua/love2d/health.lua`

- [x] Create `lua/love2d/health.lua` with `M.check()` function
- [x] Checks: `did_setup`, Neovim ≥ 0.12.2, love binary, lua-language-server, treesitter lua parser
- [x] Create `spec/health_spec.lua` (busted-style tests)
- [x] Verify: `make lint` passes

Commit: `feat(health): add :checkhealth love2d support`

---

### Step 5: `compiler/love.lua` + `utils.lua`

- [x] Create `compiler/love.lua`
- [x] Create `lua/love2d/utils.lua` (is_love2d_project, notify helpers)
- [x] Update `config.lua`: remove `setup_compiler` and `identify_love_projects` options
- [x] Update `init.lua`: delegate `is_love2d_project()` to utils.lua
- [x] Update `types.lua`: remove removed options
- [x] Verify: `make lint` passes

Commit: `feat(compiler): add compiler/love.lua, replace imperative makeprg setup`

---

### Step 6: Unified `.luarc.json` + self-contained CI

- [x] Create root `.luarc.json`
- [x] Delete `.neoconf.json`
- [x] Delete `.github/workflows/.luarc.json`
- [x] Replace `code-quality.yml` → `ci.yml` (self-contained, no external actions)
- [x] Verify: `make lint` passes, CI passes

Commit: `ci: self-contained CI with Neovim types, no external actions`

---

### Step 7: Move submodules to `libraries/`

- [x] Remove old submodules (`git rm love2d`, `git rm luasocket`)
- [x] Add submodules at new location (`libraries/love2d`, `libraries/luasocket`)
- [x] Update `config.lua`: glob targets `"love2d"` → `"libraries/love2d"`, `"luasocket"` → `"libraries/luasocket"`
- [x] Manual test: LSP resolves library paths, hover on `love` shows docs
- [x] Verify: `make lint` passes

Commit: `build(library): move type definition submodules to libraries/ directory`
Additional commit: `fix(lsp): add cmd to lua_ls config so the server can start`

---

## Remaining (Steps 8–17)

---

### Step 8: LSP verify + minimal cleanup

- [ ] Verify `lsp/lua_ls.lua` static settings are correct
- [ ] Verify `config.lua` library injection works with new paths
- [ ] Clean up dead code in `config.lua`
- [ ] Verify: `make lint` passes

Commit: `refactor(lsp): verify and clean up library path resolution`

---

### Step 9: Internal-use convention for API

- [ ] Update `types.lua`: add internal annotation to `find_src_path` and `is_love2d_project`
- [ ] Update `init.lua`: add comment noting internal-use
- [ ] Verify: `make lint` passes

Commit: `docs(api): mark find_src_path and is_love2d_project as internal-use`

---

### Step 10: Neovim 0.12.2 version bump

- [ ] Update `README.md`: ≥ 0.11 → ≥ 0.12.2
- [ ] Verify `health.lua` already checks `has("nvim-0.12.2")`
- [ ] Update CI: pin to v0.12.2 Neovim release
- [ ] Verify: `make lint` passes

Commit: `feat!: bump minimum Neovim version to 0.12.2`

---

### Step 11: Migrate tests — busted + e2e → mini.test

- [ ] Create `tests/minit.lua`
- [ ] Create `tests/love2d_spec.lua` (unit tests)
- [ ] Create `tests/platform_spec.lua` (love binary tests, pending-based)
- [ ] Create `tests/lsp_spec.lua` (unit + integration)
- [ ] Delete `spec/` directory
- [ ] Delete `tests/e2e_game.lua` and `tests/e2e_bad_game.lua`
- [ ] Update `Makefile`: test targets → `nvim -l tests/minit.lua --minitest`, lint/format → `tests/`
- [ ] Verify: `make test` passes all unit tests

Commit: `test!: migrate from busted/e2e to mini.test`

---

### Step 12: CONTRIBUTING.md

- [ ] Create `CONTRIBUTING.md`
- [ ] Verify: `make lint` passes

Commit: `docs: add CONTRIBUTING.md`

---

### Step 13: Rewrite `doc/love2d.txt`

- [ ] Rewrite vimdoc from scratch against final V3 API
- [ ] Sections: introduction, setup, commands, LSP, compiler (with errorhandler pattern), GLSL, health, API
- [ ] Remove old options, add new sections
- [ ] Verify: no broken help tags

Commit: `docs(love2d.txt): rewrite vimdoc for V3`

---

### Step 14: Update README.md

- [ ] Update version references for V3.0.0
- [ ] Update requirements (Neovim ≥ 0.12.2)
- [ ] Update installation example
- [ ] Update opts table

Commit: `docs(readme): update for V3`

---

### Step 15: Update AGENTS.md

- [ ] Remove V2 — Legacy section
- [ ] Update V3 — Current State to final architecture
- [ ] Update development commands for mini.test
- [ ] Update file structure for `libraries/` and mini.test
- [ ] Remove transition notes

Commit: `docs(agents): update AGENTS.md for completed V3`

---

### Step 16: Add test job to CI

- [ ] Add `test` job to `.github/workflows/ci.yml`
- [ ] Verify: CI passes with unit tests

Commit: `ci: add mini.test job to CI`

---

### Step 17: Update skills

- [ ] Update `.agents/skills/nvim-test/SKILL.md` for mini.test
- [ ] Update `.agents/skills/nvim-plugin/references/TESTS.md` for mini.test

Commit: `chore(skills): update nvim-test and TESTS.md for mini.test`
