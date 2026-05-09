--- E2E tests for love2d.nvim (tests/bad-game/).
---
--- Run:  make test
--- Or:   cd tests/bad-game && nvim -u repro.lua --headless -c 'luafile ../e2e_bad_game.lua' main.lua
---
--- Tests the unhappy path: runtime errors from a LÖVE project with
--- intentional bugs. Verifies `:make` populates the quickfix list
--- with correct file, line, severity, and message.

local passed = 0
local failed = 0
local skipped = 0

local function pass(name)
  passed = passed + 1
  print("TEST:PASS " .. name)
end

local function fail(name, msg)
  failed = failed + 1
  print("TEST:FAIL " .. name .. " — " .. tostring(msg))
end

local function skip(name, reason)
  skipped = skipped + 1
  print("TEST:SKIP " .. name .. " (" .. reason .. ")")
end

local function assert_eq(actual, expected, label)
  if actual == expected then
    return true
  end
  error(string.format("%s: expected %q, got %q", label or "assert", tostring(expected), tostring(actual)))
end

local function assert_contains(haystack, needle, label)
  if type(haystack) == "string" and haystack:find(needle, 1, true) then
    return true
  end
  error(string.format("%s: %q not found in %q", label or "assert", tostring(needle), tostring(haystack)))
end

local function assert_gt(actual, threshold, label)
  if type(actual) == "number" and actual > threshold then
    return true
  end
  error(string.format("%s: expected > %s, got %s", label or "assert", tostring(threshold), tostring(actual)))
end

local function has_love()
  return vim.fn.executable("love") == 1
end

local function run(name, fn)
  local ok, err = pcall(fn)
  if ok then
    pass(name)
  else
    fail(name, err)
  end
end

-- =========================================================================
-- Verify plugin is ready
-- =========================================================================

local ok, love2d = pcall(require, "love2d")
if not ok or not love2d.did_setup then
  print("TEST:ERROR love2d.nvim not initialized")
  vim.cmd("qall!")
  return
end

-- =========================================================================
-- 1. Plugin setup
-- =========================================================================

run("did_setup is true", function()
  assert_eq(require("love2d").did_setup, true, "did_setup")
end)

-- =========================================================================
-- 2. Compiler
-- =========================================================================

run("makeprg is 'love .'", function()
  assert_eq(vim.bo.makeprg, "love .", "makeprg")
end)

run("errorformat contains %trror", function()
  assert_contains(vim.bo.errorformat, "%trror", "errorformat")
end)

-- =========================================================================
-- 3. Project detection
-- =========================================================================

run("tests/bad-game is a LÖVE project", function()
  assert_eq(require("love2d").is_love2d_project(), true, "is_love2d_project")
end)

-- =========================================================================
-- 4. :make → quickfix
-- =========================================================================

if has_love() then
  vim.cmd("make! 2>&1")
  local make_done = vim.wait(10000, function()
    return #vim.fn.getqflist() > 0
  end, 500)
  local qf = vim.fn.getqflist()

  run("runtime error appears in quickfix", function()
    assert_eq(make_done, true, "make completed")
    assert_gt(#qf, 0, "quickfix count")
  end)

  run("quickfix has correct file", function()
    local item = qf[1]
    local fname = vim.fn.bufname(item.bufnr)
    assert_contains(fname, "main", "file name")
  end)

  run("quickfix has correct line (nil concat on line 10)", function()
    local item = qf[1]
    assert_eq(item.lnum, 10, "line number")
  end)

  run("quickfix error is severity error", function()
    local item = qf[1]
    assert_eq(item.type, "e", "error type")
  end)

  run("quickfix message mentions nil concat", function()
    local item = qf[1]
    assert_contains(item.text, "concatenate", "error message")
  end)
else
  for _, name in ipairs({
    "runtime error appears in quickfix",
    "quickfix has correct file",
    "quickfix has correct line (nil concat on line 10)",
    "quickfix error is severity error",
    "quickfix message mentions nil concat",
  }) do
    skip(name, "love not found")
  end
end

-- =========================================================================
-- Summary
-- =========================================================================

print(string.format("TEST:RESULTS %d passed, %d failed, %d skipped", passed, failed, skipped))

-- Safety net: kill any stray LÖVE process before exiting
local love2d = require("love2d")
if love2d.job and love2d.job.id then
  vim.fn.jobstop(love2d.job.id)
end
vim.cmd("qall!")
