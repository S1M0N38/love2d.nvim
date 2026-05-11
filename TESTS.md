# TESTS.md — love2d.nvim Test Plan

> Test framework: **mini.test** (via `lazy.minit`)
> Runner: `nvim -l tests/minit.lua --minitest`
> Single file: `nvim -l tests/minit.lua --minitest tests/<module>_spec.lua`

---

## Test structure

```
tests/
  minit.lua              — mini.test runner (lazy.minit bootstrap)
  config_spec.lua        — lua/love2d/config.lua
  utils_spec.lua         — lua/love2d/utils.lua
  events_spec.lua        — lua/love2d/events.lua
  autocmd_spec.lua       — lua/love2d/autocmd.lua
  lsp_spec.lua           — lua/love2d/lsp.lua
  job_spec.lua           — lua/love2d/job.lua
  output_spec.lua        — lua/love2d/output.lua
  health_spec.lua        — lua/love2d/health.lua
  init_spec.lua          — lua/love2d/init.lua (setup guard, public API)
  demo-game/             — Realistic LÖVE project (multi-file, states, shaders, deliberate runtime error)
```

## Principles

1. **CI-safe by default** — No external binaries (love, lua-language-server).
   Tests that need them use `pending()` to skip gracefully.
2. **Unit-test each module in isolation** — `require("love2d.<module>")` directly,
   mock/stub dependencies (vim.fn.jobstart, vim.lsp.config, etc.).
3. **Reset state between tests** — `love2d.did_setup = false`, clean autocmds,
   reset module state.
4. **Test behavior, not implementation** — Call public functions, assert on
   side effects (notifications, autocmds, vim.lsp.config state, diagnostics).
5. **Use `before_each`/`after_each`** for setup/teardown, not test-local helpers.
6. **Suppress notifications** — Override `vim.notify` in test files to keep
   output clean.

## Test conventions

- Each test file starts with `---@module 'luassert'` for annotation support.
- Use `describe()` grouped by function/behavior, `it()` for individual cases.
- Mock heavy side effects (jobstart, LSP, filesystem) — don't spawn real processes.
- Prefer `assert.are.equal()`, `assert.is_true()`, `assert.has_no.errors()`.
- For modules that depend on plugin state, call a minimal `setup()` in
  `before_each` and reset in `after_each`.

---

## Progress

### Module tests

| File | Module | Status | Notes |
|------|--------|--------|-------|
| `config_spec.lua` | `config` | ✅ 5 | Option merging, defaults |
| `utils_spec.lua` | `utils` | ✅ 12 | `path_to_love2d_project`, `path_to_main_lua`, detection tiers |
| `events_spec.lua` | `events` | ✅ 2 | Augroup + autocmd creation |
| `autocmd_spec.lua` | `autocmd` | ✅ 8 | Enter/Leave handlers, job state, output cleanup |
| `lsp_spec.lua` | `lsp` | ✅ 17 | `_resolve_library_paths`, `_build_settings`, `_enable`/`_disable`, config merging |
| `job_spec.lua` | `job` | ✅ 19 | `run`/`stop`/`watch` with mocked jobstart/jobstop, `info` status, state transitions |
| `output_spec.lua` | `output` | ✅ 21 | Buffer/window lifecycle, `append`, `push_diagnostics`, `job_opts` callbacks |
| `health_spec.lua` | `health` | ✅ 7 | Setup check, binary/server/parser/library checks |
| `init_spec.lua` | `init` | ✅ 5 | `setup()` guard, did_setup, config forwarding |

### Integration / platform tests (need `love` binary)

| Description | Status | Notes |
|-------------|--------|-------|
| Real `love` process start/stop/exit | ⬜ | `pending()` if no `love` — job happy path tested with mocks |
| Watch mode auto-restart with real process | ⬜ | `pending()` if no `love` — watch logic tested with mocks |
| `:make` populates quickfix from demo-game | ⬜ | `pending()` if no `love` |

---

## Detailed test plans per module

### `config_spec.lua`

- Defaults: `path_to_love_bin = "love"`, all others nil/default
- `setup({})` → options equal defaults
- `setup({ path_to_love_bin = "/custom" })` → only that key overridden
- `setup(nil)` → no error, defaults applied

### `utils_spec.lua`

- `path_to_love2d_project()`:
  - Returns root when CWD has `conf.lua` with `function love.conf`
  - Returns root when CWD has `main.lua` with `function love.draw`
  - Returns root when CWD has any `.lua` with `function love.load`
  - Returns nil for plain Lua project (no love callbacks/modules)
  - Walks upward to find root from subdirectory
- `path_to_main_lua()`:
  - Returns absolute path to main.lua next to conf.lua
  - Returns nil when no conf.lua or .git found

### `events_spec.lua`

- Fires `LoveProjectEnter` when detection returns a root
- Fires `LoveProjectLeave` when detection returns nil after being in project
- `check()` is idempotent (doesn't re-fire if state unchanged)

### `autocmd_spec.lua`

- On `LoveProjectEnter`: calls `job.set_project()`, shows notification
- On `LoveProjectLeave`: calls `job.clear_project()`, closes output, notifies

### `lsp_spec.lua`

- `_resolve_library_paths()`: returns 0–2 paths (depends on submodules)
- `_enable()`: merges love paths into `vim.lsp.config.lua_ls` settings
- `_disable()`: strips love paths, keeps user paths, notifies running clients
- `_build_settings()`: returns correct LuaJIT, diagnostics, workspace table
- `setup()`: creates User autocmds, calls `vim.lsp.enable("lua_ls")`

### `job_spec.lua`

- `set_project()` / `clear_project()`: state transitions
- `run()`: starts process, notifies, handles already-running guard
- `stop()`: kills process, cleans watch state, notifies
- `watch()`: creates BufWritePost autocmd, starts process
- `_on_save()`: debounce logic (generation counter)
- `info()`: notification with project status

### `output_spec.lua`

- `state()`: returns "hidden"/"unfocused"/"focused"
- `open()` / `close()` / `toggle()`: window lifecycle
- `append()`: adds lines to buffer, filters empty strings
- `push_diagnostics()`: parses `file:line: msg`, sets vim.diagnostic
- `clear_diagnostics()`: resets namespace
- `_goto_file_line()`: parses cursor line, opens file (harder to unit test)
- `start()` / `stop()`: lifecycle hooks

### `health_spec.lua`

- Reports error when `did_setup = false`
- Reports ok when setup was called
- Checks love binary (ok or warn)
- Checks lua-language-server (ok or warn)
- Checks type definition libraries
- Uses custom `path_to_love_bin` from config

### `init_spec.lua`

- `setup()` sets `did_setup = true`
- Second `setup()` warns and returns early
- `setup()` calls config, lsp, autocmd, events modules
