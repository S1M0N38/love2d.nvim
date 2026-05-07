---
name: nvim-test
description: >
  Execute tests and diagnose failures for love2d.nvim. Use when the user says
  "run tests", "run the suite", or asks to execute the test suite (full or single file).
  Also use when the user pastes test error output, asks what a test failure means,
  or needs help fixing a broken test. The test stack is busted + nlua + luassert with
  _spec.lua files. Do not trigger for writing tests, learning test APIs, setting up
  testing from scratch, or non-Neovim tools.
---

# Running love2d.nvim Tests

This skill covers **running** tests and **diagnosing failures**. For how to
*write* tests, see the `nvim-plugin` skill's `references/TESTS.md`.

## Test stack

- **busted** — Test framework (describe/it blocks, before_each/after_each)
- **nlua** — Neovim's embedded Lua interpreter (provides `vim` API in tests)
- **luassert** — Assertion library (assert.are.equal, assert.is_true, etc.)

## Configuration

The `.busted` file configures the test runner:

```lua
return {
  _all = {
    coverage = false,
    lpath = "lua/?.lua;lua/?/init.lua",
    lua = "nlua",
  },
  default = {
    verbose = true,
  },
}
```

- `lua = "nlua"` — Runs tests inside Neovim's Lua runtime
- `lpath` — Lua module search path (points to `lua/` directory)

## Running tests

### Full test suite

```bash
busted
```

### Single test file

```bash
busted spec/love2d_spec.lua
```

### Specific test by name pattern

```bash
busted -o utf_terminal -p "find_src_path" spec/love2d_spec.lua
```

### With verbose output

```bash
busted -v
```

### Run and filter by describe/it name

```bash
busted --filter="job management"
```

## Reading test output

busted reports with:

- **Green `✓`** = passed test case
- **Red `✗` or `Failure`** = failed test case (with error details below)
- Summary line shows total assertions, passed, failed, and errors
- Failures show file, line number, and expected vs actual values

### Example output

```
✓ love2d platform does not start with wrong path_to_love_bin
✓ love2d platform starts
✓ love2d platform runs game
✗ love2d platform stops
    spec/love2d_spec.lua:85: Expected:
    nil
    Got:
    number: 12345
    stack traceback:
      spec/love2d_spec.lua:85: in function <spec/love2d_spec.lua:84>
```

### Diagnosing failures

1. **Read the error message** — luassert shows expected vs actual values
2. **Check the line number** — it points to the assertion that failed
3. **Check the stack trace** — it shows the call chain leading to the failure
4. **Reproduce in isolation** — run just the failing file: `busted spec/failing_spec.lua`
5. **Check for state leaks** — if a test passes alone but fails with the suite,
   something in a previous test didn't clean up (missing `after_each`)

### Common failure patterns

| Error | Cause | Fix |
|-------|-------|-----|
| `Expected: X, Got: Y` | Wrong return value | Check the function logic |
| `attempt to index nil value` | Module not loaded or config not set | Call `setup()` in `before_each` |
| `test passes alone, fails in suite` | State leak between tests | Check `after_each` cleanup, restore stubs |
| `timeout / hangs` | `vim.wait` not resolving | Check that async operations complete properly |
| `nlua: command not found` | nlua not installed | Install via luarocks: `luarocks install nlua` |
| `module not found` | lpath not configured | Check `.busted` lpath setting |

## Prerequisites

Ensure the following tools are installed:

```bash
# Check busted
busted --version

# Check nlua
nlua --version

# Install if missing (via luarocks)
luarocks install busted
luarocks install nlua
```

## Project test files

- **`.busted`** — Test runner configuration. Do not recreate this file.
- **`spec/love2d_spec.lua`** — Game execution and job management tests
- **`spec/lsp_spec.lua`** — LSP configuration tests
- **`tests/game/`** — Sample LÖVE game used by tests

## Platform considerations

love2d.nvim tests require the LÖVE binary. Platform-specific paths are resolved
inside test files:

| Platform | Default love binary |
|----------|-------------------|
| macOS | `/Applications/love.app/Contents/MacOS/love` |
| Linux | `/usr/bin/love` |
| Windows | Not supported in CI |

If LÖVE is not installed, game execution tests will fail. LSP tests that don't
run the game binary can still pass without LÖVE installed.
