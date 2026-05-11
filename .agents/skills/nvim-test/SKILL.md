---
name: nvim-test
description: >
  Execute tests and diagnose failures for love2d.nvim. Use when the user says
  "run tests", "run the suite", or asks to execute the test suite (full or single file).
  Also use when the user pastes test error output, asks what a test failure means,
  or needs help fixing a broken test. The test stack is mini.test via lazy.minit
  with *_spec.lua files in tests/. Do not trigger for writing tests, learning test
  APIs, setting up testing from scratch, or non-Neovim tools.
---

# Running love2d.nvim Tests

This skill covers **running** tests and **diagnosing failures**.

## Test stack

- **mini.test** — Test framework (describe/it blocks, before_each/after_each)
- **lazy.minit** — Bootstrap via `tests/minit.lua` (resolves mini.test + luassert)

## Running tests

### Full test suite

```bash
make test
# or: nvim -l tests/minit.lua --minitest
```

### Single test file

```bash
make test-one MODULE=config
# or: nvim -l tests/minit.lua --minitest tests/config_spec.lua
```

### Format check

```bash
make lint
```

### Full check (lint + test)

```bash
make check
```

## Test files

Each source module has a matching test file:

| Test file | Module tested |
|-----------|---------------|
| `tests/config_spec.lua` | `love2d.config` |
| `tests/utils_spec.lua` | `love2d.utils` |
| `tests/init_spec.lua` | `love2d` (init) |
| `tests/events_spec.lua` | `love2d.events` |
| `tests/autocmd_spec.lua` | `love2d.autocmd` |
| `tests/lsp_spec.lua` | `love2d.lsp` |
| `tests/job_spec.lua` | `love2d.job` |
| `tests/output_spec.lua` | `love2d.output` |
| `tests/health_spec.lua` | `love2d.health` |

## Reading test output

mini.test reports with:

- **Green `✓`** = passed
- **Red `✗`** = failed (with error details below)
- Summary line shows passed, failed, and total

### Diagnosing failures

1. **Read the error message** — shows expected vs actual values
2. **Check the line number** — points to the failing assertion
3. **Check for state leaks** — if a test passes alone but fails in the suite,
   something didn't clean up (missing `after_each`)
4. **Reproduce in isolation** — `make test-one MODULE=<name>`

### Common failure patterns

| Error | Cause | Fix |
|-------|-------|-----|
| `Expected: X, Got: Y` | Wrong return value | Check the function logic |
| `attempt to index nil value` | Module not loaded or config not set | Call `setup()` in `before_each` |
| `test passes alone, fails in suite` | State leak between tests | Add `after_each` cleanup, reset `did_setup` |
| `timeout / hangs` | `vim.wait` not resolving | Check async operations complete |

## Test conventions

- Reset `love2d.did_setup = false` in `before_each`
- Suppress notifications: override `vim.notify` in test files
- Mock heavy side effects (jobstart, LSP, filesystem) — don't spawn real processes
- Tests needing the `love` binary use `pending()` to skip gracefully

## Project test files

- **`tests/minit.lua`** — mini.test runner bootstrap
- **`tests/*_spec.lua`** — Test files (one per module)
- **`tests/demo-game/`** — Realistic LÖVE game fixture
