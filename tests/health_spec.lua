---@module 'luassert'

local love2d, health

---Reload all love2d modules to get a clean state.
local function reset_setup()
  for _, mod in ipairs({
    "love2d",
    "love2d.config",
    "love2d.lsp",
    "love2d.autocmd",
    "love2d.events",
    "love2d.utils",
    "love2d.job",
    "love2d.output",
    "love2d.health",
  }) do
    package.loaded[mod] = nil
  end
  love2d = require("love2d")
  health = require("love2d.health")
end

---------------------------------------------------------------------------
-- vim.health capture helpers
---------------------------------------------------------------------------

local captured = {}

local original_health = {
  start = vim.health.start,
  ok = vim.health.ok,
  warn = vim.health.warn,
  error = vim.health.error,
  info = vim.health.info,
}

local function capture_health()
  captured = {}
  vim.health.start = function(name)
    table.insert(captured, { type = "start", name = name })
  end
  vim.health.ok = function(msg)
    table.insert(captured, { type = "ok", msg = msg })
  end
  vim.health.warn = function(msg, advice)
    table.insert(captured, { type = "warn", msg = msg, advice = advice })
  end
  vim.health.error = function(msg, advice)
    table.insert(captured, { type = "error", msg = msg, advice = advice })
  end
  vim.health.info = function(msg)
    table.insert(captured, { type = "info", msg = msg })
  end
end

local function restore_health()
  vim.health.start = original_health.start
  vim.health.ok = original_health.ok
  vim.health.warn = original_health.warn
  vim.health.error = original_health.error
  vim.health.info = original_health.info
end

---Find all captured entries of a given type.
---@param type string "start"|"ok"|"warn"|"error"|"info"
---@return table[]
local function find_entries(type)
  local results = {}
  for _, entry in ipairs(captured) do
    if entry.type == type then
      table.insert(results, entry)
    end
  end
  return results
end

---Find a captured entry by type and optional pattern match on msg/name.
---@param type string
---@param pattern? string Lua pattern.
---@return table? entry
local function find_entry(type, pattern)
  for _, entry in ipairs(captured) do
    if entry.type == type then
      local text = entry.msg or entry.name or ""
      if not pattern or text:match(pattern) then
        return entry
      end
    end
  end
  return nil
end

---Collect all msg fields across specified types.
---@param types string[]
---@return string[]
local function collect_msgs(types)
  local msgs = {}
  for _, t in ipairs(types) do
    for _, e in ipairs(find_entries(t)) do
      table.insert(msgs, e.msg)
    end
  end
  return msgs
end

---Check if any message in a list matches a pattern.
---@param msgs string[]
---@param pattern string
---@return boolean
local function any_match(msgs, pattern)
  for _, msg in ipairs(msgs) do
    if msg:match(pattern) then
      return true
    end
  end
  return false
end

---Count how many `start` sections were emitted.
---@return integer
local function count_sections()
  return #find_entries("start")
end

---Find all section names that were started.
---@return string[]
local function section_names()
  local names = {}
  for _, e in ipairs(find_entries("start")) do
    table.insert(names, e.name)
  end
  return names
end

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------

describe("health", function()
  before_each(function()
    reset_setup()
    capture_health()
  end)

  after_each(function()
    restore_health()
  end)

  ---------------------------------------------------------------------------
  -- Section structure
  ---------------------------------------------------------------------------

  describe("sections", function()
    it("emits 9 health sections", function()
      love2d.setup({})
      health.check()
      assert.equal(9, count_sections())
    end)

    it("includes expected section names", function()
      love2d.setup({})
      health.check()
      local names = section_names()
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("setup")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("Neovim")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("LÖVE")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("lua%-language%-server")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("[Tt]ype")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("Treesitter")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("GLSL")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("Runtime")
      end))
      assert.is_truthy(vim.iter(names):any(function(n)
        return n:match("Configuration")
      end))
    end)
  end)

  ---------------------------------------------------------------------------
  -- Setup check
  ---------------------------------------------------------------------------

  describe("setup", function()
    it("reports error when setup() was not called", function()
      health.check()
      local entry = find_entry("error", "setup")
      assert.is_not_nil(entry)
      assert.is_truthy(entry.advice and entry.advice:match("setup"))
    end)

    it("reports ok when setup() was called", function()
      love2d.setup({})
      health.check()
      local entry = find_entry("ok", "setup")
      assert.is_not_nil(entry)
    end)
  end)

  ---------------------------------------------------------------------------
  -- Neovim version check
  ---------------------------------------------------------------------------

  describe("Neovim version", function()
    it("checks Neovim version", function()
      love2d.setup({})
      health.check()
      -- Should mention Neovim version (ok or error)
      local msgs = collect_msgs({ "ok", "error" })
      assert.is_true(any_match(msgs, "Neovim"))
    end)

    it("formats version strings as major.minor.patch", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "error" })
      -- Must match "X.Y.Z >= X.Y.Z" — NOT a raw table address like "table: 0x..."
      assert.is_true(any_match(msgs, "%d+%.%d+%.%d+ >= %d+%.%d+%.%d+"))
      assert.is_false(any_match(msgs, "table: 0x"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- LÖVE binary check
  ---------------------------------------------------------------------------

  describe("LÖVE binary", function()
    it("mentions the configured binary path", function()
      love2d.setup({ path_to_love_bin = "/custom/path/love" })
      health.check()
      local msgs = collect_msgs({ "ok", "warn" })
      assert.is_true(any_match(msgs, "/custom/path/love"))
    end)

    it("reports ok or warn for the binary", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "warn" })
      assert.is_true(any_match(msgs, "LÖVE"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- lua-language-server check
  ---------------------------------------------------------------------------

  describe("lua-language-server", function()
    it("checks for lua-language-server", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "warn", "info" })
      assert.is_true(any_match(msgs, "lua%-language%-server"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- Type definitions check
  ---------------------------------------------------------------------------

  describe("type definitions", function()
    it("checks for type definition libraries", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "warn" })
      assert.is_true(any_match(msgs, "[Dd]efinitions"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- Treesitter parsers check
  ---------------------------------------------------------------------------

  describe("Treesitter parsers", function()
    it("checks for lua parser", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "warn" })
      assert.is_true(any_match(msgs, "lua"))
    end)

    it("checks for glsl parser (ok or info)", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "info" })
      assert.is_true(any_match(msgs, "glsl"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- GLSL injection check
  ---------------------------------------------------------------------------

  describe("GLSL injection", function()
    it("checks for injection query", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "warn" })
      assert.is_true(any_match(msgs, "GLSL") or any_match(msgs, "injection"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- Runtime state check
  ---------------------------------------------------------------------------

  describe("runtime state", function()
    it("reports project detection status", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "info", "warn" })
      assert.is_true(any_match(msgs, "project") or any_match(msgs, "LÖVE"))
    end)
  end)

  ---------------------------------------------------------------------------
  -- Config validation check
  ---------------------------------------------------------------------------

  describe("configuration", function()
    it("reports ok when config is valid", function()
      love2d.setup({})
      health.check()
      local msgs = collect_msgs({ "ok", "warn" })
      assert.is_true(any_match(msgs, "unknown configuration"))
    end)

    it("warns on unknown config keys", function()
      love2d.setup({ typo_option = true })
      health.check()
      local entries = find_entries("warn")
      local found = false
      for _, e in ipairs(entries) do
        if e.msg and e.msg:match("typo_option") then
          found = true
          assert.is_truthy(e.advice and e.advice:match("path_to_love_bin"))
        end
      end
      assert.is_true(found)
    end)

    it("accepts valid output option", function()
      love2d.setup({ output = false })
      health.check()
      local entries = find_entries("warn")
      local found_unknown = false
      for _, e in ipairs(entries) do
        if e.msg and e.msg:match("unknown configuration") then
          found_unknown = true
        end
      end
      assert.is_false(found_unknown)
    end)
  end)

  ---------------------------------------------------------------------------
  -- Robustness
  ---------------------------------------------------------------------------

  describe("robustness", function()
    it("runs without errors when setup() was not called", function()
      assert.has_no.errors(function()
        health.check()
      end)
    end)

    it("runs without errors when setup() was called", function()
      assert.has_no.errors(function()
        love2d.setup({})
        health.check()
      end)
    end)

    it("runs without errors with custom config", function()
      assert.has_no.errors(function()
        love2d.setup({ path_to_love_bin = "/nonexistent/love" })
        health.check()
      end)
    end)
  end)
end)
