--- E2E tests for love2d.nvim (tests/game/).
---
--- Run:  make test
--- Or:   cd tests/game && nvim -u repro.lua --headless -c 'luafile ../e2e_game.lua' main.lua
---
--- Tests the happy path: plugin setup, compiler configuration,
--- and project detection from the working LÖVE game project.

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

run("tests/game is a LÖVE project", function()
  assert_eq(require("love2d").is_love2d_project(), true, "is_love2d_project")
end)

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
