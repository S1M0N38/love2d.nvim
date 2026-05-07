# Neovim Plugin Testing Recipes

A catalog of testing patterns for Neovim Lua plugins using **busted** +
**luassert** with `describe`/`it` blocks, running via **nlua**.

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
10. [Testing Highlights](#10-testing-highlights)
11. [Testing Autocmds](#11-testing-autocmds)
12. [Testing Keymaps](#12-testing-keymaps)
13. [Test Anti-Patterns](#13-test-anti-patterns)
14. [Advanced Testing Patterns](#14-advanced-testing-patterns)

---

## 1. Test File Structure

### File naming and location

Test files go in `spec/` and must end in `_spec.lua` (this is how busted
discovers them).

### Busted configuration (`.busted`)

love2d.nvim uses a `.busted` config file to set up nlua as the test runner:

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
  tests = {
    verbose = true,
  },
}
```

Key settings:
- `lua = "nlua"` — Uses nlua (Neovim's embedded Lua) for test execution
- `lpath` — Lua module search path pointing to `lua/` directory

### Basic structure

```lua
local MyModule = require("myplugin.module")

describe("module name", function()
  before_each(function()
    -- setup runs before each it()
  end)

  after_each(function()
    -- cleanup runs after each it()
  end)

  it("does something specific", function()
    assert.are.equal(expected, actual)
  end)
end)
```

### Nested describe blocks

`before_each`/`after_each` cascade from outer to inner blocks:

```lua
describe("parser", function()
  before_each(function()
    -- runs before every it() at any nesting level
  end)

  describe("lua files", function()
    it("parses functions", function() end)
  end)

  describe("python files", function()
    it("parses classes", function() end)
  end)
end)
```

---

## 2. Assertions Quick Reference

The most commonly used luassert assertions:

### Equality

```lua
-- Deep comparison (tables, lists, strings)
assert.are.same({ a = 1 }, { a = 1 })

-- Reference/value equality
assert.are.equal("hello", some_string)
assert.equal(42, some_number)       -- .are is optional for equal
```

### Boolean / nil checks

```lua
assert.is_true(expr)
assert.is_false(expr)
assert.is_nil(result)
assert.is_not_nil(result)
```

### Negation modifier

Chain `is_not` (or `not`) to invert any assertion:

```lua
assert.is_not_nil(result)
assert.are_not.same(t1, t2)
```

### Error checking

```lua
-- Assert function does NOT throw
assert.has_no.errors(function()
  health.check()
end)

-- Assert function DOES throw
assert.has_error(function()
  error("boom")
end)

-- Assert error matches pattern
assert.has_error(function()
  error("invalid input")
end, "invalid")
```

### String matching

```lua
assert.matches("pattern", actual_string)
```

### Truthy / Falsy

```lua
assert.is_truthy(val)   -- not false and not nil
assert.is_falsy(val)    -- false or nil
assert.truthy(val)      -- shorthand
assert.falsy(val)       -- shorthand
```

### Full API

luassert also includes: `assert.unique`, `assert.near`,
`assert.error_matches`, `assert.returned_arguments`, plus spies/stubs/mocks
via `require("luassert.spy")` and `require("luassert.stub")`.

---

## 3. Table-Driven Tests

The dominant pattern in production Neovim plugin test suites. Define test cases
as a table, loop over them.

### Simple cases — input/output pairs

```lua
describe("split_words", function()
  local cases = {
    { "abcd",       { "abcd" } },
    { "abcd.",      { "abcd", "." } },
    { "abc 123",    { "abc", " ", "123" } },
    { "café",       { "café" } },
  }

  for _, case in ipairs(cases) do
    it(case[1] .. " => " .. vim.inspect(case[2]), function()
      assert.are.same(case[2], MyModule.split_words(case[1]))
    end)
  end
end)
```

### Named cases with check function

For more complex cases where the expected behavior varies:

```lua
local cases = {
  {
    name = "inline word change",
    input = "foo",
    expected = "bar",
  },
  {
    name = "handles empty string",
    input = "",
    expected = "",
  },
}

for _, case in ipairs(cases) do
  it(case.name, function()
    assert.are.same(case.expected, MyModule.process(case.input))
  end)
end
```

---

## 4. Stubbing and Restoring

### Basic stub/restore pattern

Save the original in `before_each`, override it, restore in `after_each`:

```lua
describe("my function", function()
  local original_notify

  before_each(function()
    original_notify = vim.notify
  end)

  after_each(function()
    vim.notify = original_notify
  end)

  it("calls vim.notify with error level", function()
    local calls = {}
    vim.notify = function(msg, level, opts)
      table.insert(calls, { msg = msg, level = level, opts = opts })
    end

    MyModule.error("oops")

    assert.are.same({
      { msg = "oops", level = vim.log.levels.ERROR, opts = { title = "MyPlugin" } },
    }, calls)
  end)
end)
```

### Stubbing module functions

```lua
local Config = require("myplugin.config")

before_each(function()
  original = Config.get_client
  Config.get_client = function()
    return { id = 42 }
  end
end)

after_each(function()
  Config.get_client = original
end)
```

### luassert stub (formal)

```lua
local stub = require("luassert.stub")

it("stubs vim.notify", function()
  stub(vim, "notify")
  MyModule.warn("test")
  assert.stub(vim.notify).was_called_with("test", vim.log.levels.WARN, match.is_table())
  vim.notify:revert()  -- restore
end)
```

---

## 5. Creating Test Buffers

Use scratch buffers to test buffer-level logic:

```lua
describe("buffer operations", function()
  local buf, win

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)  -- unlisted, scratch
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end)

  after_each(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)

  it("detects function at cursor", function()
    vim.bo[buf].filetype = "lua"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "local function test()",
      "  return 42",
      "end",
    })
    vim.api.nvim_win_set_cursor(win, { 2, 2 })

    local result = MyModule.get_function_at_cursor()
    assert.is_not_nil(result)
  end)
end)
```

---

## 6. Testing with File Buffers

Some functionality requires real file buffers (not scratch buffers):

```lua
it("reads file content", function()
  local tmp = vim.fn.tempname() .. ".lua"
  vim.fn.writefile({ "local foo = 1" }, tmp)
  local file_buf = vim.fn.bufadd(tmp)
  vim.fn.bufload(file_buf)
  vim.bo[file_buf].buflisted = true
  vim.api.nvim_win_set_buf(win, file_buf)

  -- ... test logic

  vim.fn.delete(tmp)
  vim.api.nvim_buf_delete(file_buf, { force = true })
end)
```

---

## 7. Testing Config Changes

Test different configurations without cross-test contamination:

```lua
describe("config behavior", function()
  local original_config

  before_each(function()
    original_config = vim.deepcopy(require("myplugin.config"))
  end)

  after_each(function()
    local Config = require("myplugin.config")
    for k, v in pairs(original_config) do
      Config[k] = v
    end
  end)

  it("uses default value", function()
    require("myplugin").setup({})
    assert.are.equal("default", require("myplugin.config").some_option)
  end)

  it("uses custom value", function()
    require("myplugin").setup({ some_option = "custom" })
    assert.are.equal("custom", require("myplugin.config").some_option)
  end)
end)
```

---

## 8. Conditional Tests

Some tests depend on platform or external tools. Skip gracefully:

```lua
local function pending(msg)
  print("PENDING: " .. msg)
  assert.is_true(true)
end

it("starts game on macOS", function()
  if vim.fn.has("mac") ~= 1 then
    pending("macOS not available")
    return
  end
  -- ... actual test
end)
```

For love2d.nvim, platform-specific paths are important:

```lua
local opts
if vim.fn.has("mac") == 1 then
  opts = { path_to_love_bin = "/Applications/love.app/Contents/MacOS/love" }
elseif vim.fn.has("linux") == 1 then
  opts = { path_to_love_bin = "/usr/bin/love" }
else
  error("OS not supported")
end
```

---

## 9. Testing Notifications

Capture and assert notification calls:

```lua
describe("notifications", function()
  local notify_calls, original_notify

  before_each(function()
    original_notify = vim.notify
    notify_calls = {}
    vim.notify = function(msg, level, opts)
      table.insert(notify_calls, {
        msg = msg,
        level = level,
        title = opts and opts.title,
      })
    end
  end)

  after_each(function()
    vim.notify = original_notify
  end)

  it("sends error notification with title", function()
    MyModule.error("something failed")
    assert.are.equal(1, #notify_calls)
    assert.are.equal("something failed", notify_calls[1].msg)
    assert.are.equal(vim.log.levels.ERROR, notify_calls[1].level)
  end)
end)
```

---

## 10. Testing Highlights

Verify highlight groups are defined correctly:

```lua
describe("highlights", function()
  it("defines link groups with default = true", function()
    MyModule.set_hl()
    local hl = vim.api.nvim_get_hl(0, { name = "MyPluginTitle", link = false })
    assert.is_not_nil(hl.link)
    assert.are.equal("FloatTitle", hl.link)
  end)
end)
```

---

## 11. Testing Autocmds

Verify autocmds fire correctly:

```lua
describe("autocmds", function()
  after_each(function()
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_restart_on_save")
  end)

  it("creates autocmd when restart_on_save is enabled", function()
    love2d.setup({
      path_to_love_bin = opts.path_to_love_bin,
      restart_on_save = true,
    })

    local success, augroups = pcall(vim.api.nvim_get_autocmds, {
      group = "love2d_restart_on_save",
    })
    assert.truthy(success)
    assert.truthy(#augroups > 0)
    assert.are.equal("BufWritePost", augroups[1].event)
  end)
end)
```

---

## 12. Testing Keymaps

Verify keymaps are set correctly:

```lua
describe("keymaps", function()
  it("creates <Plug> mapping", function()
    MyModule.setup({})
    local maps = vim.api.nvim_get_keymap("n")
    local found = false
    for _, m in ipairs(maps) do
      if m.lhs == "<Plug>(MyPluginAction)" then
        found = true
        assert.is_not_nil(m.callback)
        break
      end
    end
    assert.is_true(found)
  end)
end)
```

---

## 13. Test Anti-Patterns

### ❌ Don't: Leave state behind between tests

```lua
-- ❌ Job leaks into the next test
it("starts a game", function()
  love2d.run("tests/game")
  -- ... forgot to stop
end)

-- ✅ Always clean up in after_each
after_each(function()
  if love2d.job and love2d.job.id then
    love2d.stop()
    vim.wait(500)
  end
end)
```

### ❌ Don't: Mutate global state without restoring

```lua
-- ❌ vim.notify is permanently mocked
it("checks something", function()
  vim.notify = function() end
end)

-- ✅ Save and restore
local original_notify
before_each(function()
  original_notify = vim.notify
end)
after_each(function()
  vim.notify = original_notify
end)
```

### ❌ Don't: Test implementation details

```lua
-- ❌ Brittle — breaks if you rename the internal variable
assert.are.equal("my_value", MyModule._internal_state)

-- ✅ Test observable behavior
assert.are.equal("expected output", MyModule.public_api())
```

### ❌ Don't: Skip vim.wait for async operations

```lua
-- ❌ job.start is async — checking immediately may fail
love2d.run("tests/game")
assert.is_not_nil(love2d.job.id)

-- ✅ Wait for the job to actually start
love2d.run("tests/game")
vim.wait(1000)
assert.is_not_nil(love2d.job.id)
```

---

## 14. Advanced Testing Patterns

### Error capture helper

Capture error messages without mocking the entire notification system:

```lua
local function capture_errors(mod, method)
  local errors = {}
  local original = mod[method]
  mod[method] = function(msg)
    table.insert(errors, msg)
  end
  return errors, function()
    mod[method] = original
  end
end
```

### Waiting for async operations

Job start/stop and `vim.schedule` callbacks need explicit waiting:

```lua
it("waits for job to start", function()
  love2d.run("tests/game")
  vim.wait(1000)
  assert.is_not_nil(love2d.job.id)

  love2d.stop()
  vim.wait(500) -- wait for on_exit callback
  assert.is_nil(love2d.job.id)
end)
```

### Platform-aware testing

love2d.nvim needs to handle different platforms:

```lua
local function get_love_binary()
  if vim.fn.has("mac") == 1 then
    return "/Applications/love.app/Contents/MacOS/love"
  elseif vim.fn.has("linux") == 1 then
    return "/usr/bin/love"
  end
  return nil
end

it("starts game with platform binary", function()
  local bin = get_love_binary()
  if not bin then
    print("PENDING: No love binary for this platform")
    return
  end
  love2d.setup({ path_to_love_bin = bin })
  love2d.run("tests/game")
  vim.wait(1000)
  assert.is_not_nil(love2d.job.id)
  love2d.stop()
  vim.wait(500)
end)
```

### Testing with vim.wait

`vim.schedule` and async job callbacks need explicit waiting:

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

### Buffer-local keymap testing

Use `nvim_buf_get_keymap` to test buffer-local keymaps:

```lua
it("sets buffer-local keymaps in plugin window", function()
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
```
