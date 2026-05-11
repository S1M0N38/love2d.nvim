# Neovim Plugin Testing Recipes

A catalog of testing patterns for Neovim Lua plugins using **mini.test**
(via `lazy.minit`) with `describe`/`it` blocks running inside Neovim.

> For running tests and analyzing output, use the `nvim-test` skill.

---

## Table of Contents

1. [Test File Structure](#1-test-file-structure)
2. [Assertions Quick Reference](#2-assertions-quick-reference)
3. [Table-Driven Tests](#3-table-driven-tests)
4. [Stubbing and Restoring](#4-stubbing-and-restoring)
5. [Creating Test Buffers](#5-creating-test-buffers)
6. [Testing with File Buffers](#6-testing-with-file-buffers)
7. [Testing Config Changes](#7-testing-config-changes)
8. [Conditional Tests](#8-conditional-tests)
9. [Testing Notifications](#9-testing-notifications)
10. [Testing Autocmds](#10-testing-autocmds)
11. [Testing Keymaps](#11-testing-keymaps)
12. [Test Anti-Patterns](#12-test-anti-patterns)
13. [Advanced Testing Patterns](#13-advanced-testing-patterns)

---

## 1. Test File Structure

### File naming and location

Test files go in `tests/` and must end in `_spec.lua`. Each module has a
matching spec file:

```
tests/
  minit.lua           — mini.test runner (lazy.minit bootstrap)
  config_spec.lua     — tests for lua/love2d/config.lua
  utils_spec.lua      — tests for lua/love2d/utils.lua
  init_spec.lua       — tests for lua/love2d/init.lua
  ...
```

### Test file template

```lua
---@module 'luassert'

local module = require("love2d.module")

describe("module", function()
  before_each(function()
    -- Reset state
    love2d.did_setup = false
  end)

  after_each(function()
    -- Clean up
  end)

  it("does something", function()
    assert.are.equal(expected, actual)
  end)
end)
```

---

## 2. Assertions Quick Reference

mini.test emulates busted-style assertions via luassert:

```lua
-- Equality
assert.are.equal(expected, actual)       -- strict equality (==)
assert.are_not.equal(expected, actual)

-- Boolean
assert.is_true(value)
assert.is_false(value)

-- Nil / truthy
assert.is_nil(value)
assert.is_not_nil(value)
assert.truthy(value)  -- any non-nil/non-false value
assert.falsy(value)

-- Errors
assert.has_error(function() error("boom") end)
assert.has_no.errors(function() safe_call() end)

-- Tables
assert.are.same({ a = 1 }, { a = 1 })   -- deep comparison
```

---

## 3. Table-Driven Tests

Test multiple inputs with the same logic:

```lua
describe("detection tiers", function()
  local cases = {
    { "conf.lua with love.conf", true },
    { "main.lua with love.draw", true },
    { "plain Lua project", false },
  }

  for _, case in ipairs(cases) do
    it("detects: " .. case[1], function()
      -- set up files for case[1]
      -- assert.are.equal(case[2], result)
    end)
  end
end)
```

---

## 4. Stubbing and Restoring

### Manual save/restore

```lua
local original_fn
before_each(function()
  original_fn = vim.fn.jobstart
end)
after_each(function()
  vim.fn.jobstart = original_fn
end)

it("starts a job", function()
  local captured_cmd
  vim.fn.jobstart = function(cmd, opts)
    captured_cmd = cmd
    return 1
  end
  job.run()
  assert.are.equal("love .", captured_cmd)
end)
```

---

## 5. Creating Test Buffers

```lua
it("works with a buffer", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'function love.draw()',
    '  love.graphics.print("hello")',
    'end',
  })
  vim.api.nvim_set_current_buf(buf)
  -- ... test ...
  vim.api.nvim_buf_delete(buf, { force = true })
end)
```

---

## 6. Testing with File Buffers

```lua
it("reads a real file", function()
  local buf = vim.fn.bufadd("tests/demo-game/main.lua")
  vim.fn.bufload(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  assert.truthy(#lines > 0)
end)
```

---

## 7. Testing Config Changes

```lua
describe("config", function()
  after_each(function()
    config.options = {}
  end)

  it("merges user options with defaults", function()
    config.setup({ path_to_love_bin = "/custom/love" })
    assert.are.equal("/custom/love", config.options.path_to_love_bin)
  end)

  it("applies defaults when no opts given", function()
    config.setup(nil)
    assert.are.equal("love", config.options.path_to_love_bin)
  end)
end)
```

---

## 8. Conditional Tests

Skip tests when external tools are unavailable:

```lua
it("runs LÖVE project", function()
  if not vim.fn.executable("love") then
    pending("love binary not found")
    return
  end
  -- ... test that needs love ...
end)
```

---

## 9. Testing Notifications

Capture and assert on notifications:

```lua
local notified = {}
local original_notify

before_each(function()
  notified = {}
  original_notify = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(notified, { msg = msg, level = level })
  end
end)

after_each(function()
  vim.notify = original_notify
end)

it("warns when no project detected", function()
  job.run()
  assert.equal(1, #notified)
  assert.truthy(notified[1].msg:match("No LÖVE project"))
end)
```

---

## 10. Testing Autocmds

```lua
describe("autocmds", function()
  after_each(function()
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_autocmd")
  end)

  it("creates autocmd on setup", function()
    autocmd.setup()
    local cmds = vim.api.nvim_get_autocmds({
      group = "love2d_autocmd",
    })
    assert.truthy(#cmds > 0)
  end)
end)
```

---

## 11. Testing Keymaps

```lua
describe("keymaps", function()
  it("sets buffer-local keymaps", function()
    local buf = vim.api.nvim_create_buf(false, true)
    -- ... setup plugin on buf ...
    local maps = vim.api.nvim_buf_get_keymap(buf, "n")
    local found = false
    for _, m in ipairs(maps) do
      if m.lhs == "q" then
        found = true
        assert.are.equal("Close window", m.desc)
        break
      end
    end
    assert.is_true(found)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
end)
```

---

## 12. Test Anti-Patterns

### Don't: Leave state behind between tests

```lua
-- Bad: Job leaks into the next test
it("starts a game", function()
  job.run()
  -- ... forgot to stop
end)

-- Good: Always clean up in after_each
after_each(function()
  if job.state and job.state.id then
    job.stop()
  end
end)
```

### Don't: Mutate global state without restoring

```lua
-- Bad: vim.notify is permanently mocked
it("checks something", function()
  vim.notify = function() end
end)

-- Good: Save and restore
local original_notify
before_each(function()
  original_notify = vim.notify
end)
after_each(function()
  vim.notify = original_notify
end)
```

### Don't: Test implementation details

```lua
-- Bad: Brittle — breaks if internal variable is renamed
assert.are.equal("my_value", module._internal_state)

-- Good: Test observable behavior
assert.are.equal("expected output", module.public_api())
```

---

## 13. Advanced Testing Patterns

### Error capture helper

```lua
local function capture_notifications()
  local captured = {}
  local original = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(captured, { msg = msg, level = level })
  end
  return captured, function()
    vim.notify = original
  end
end
```

### Waiting for async operations

```lua
it("waits for scheduled callback", function()
  local done = false
  vim.schedule(function()
    done = true
  end)
  vim.wait(1000, function()
    return done
  end, 50)
  assert.is_true(done)
end)
```

### Testing LSP config changes

```lua
it("injects library paths into lua_ls", function()
  lsp._enable()
  local cfg = vim.lsp.config.lua_ls
  local library = cfg.settings.Lua.workspace.library
  assert.truthy(#library > 0)
end)
```
