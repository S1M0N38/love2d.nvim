local love2d = require("love2d")
local health = require("love2d.health")

---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function() end

local function reset_setup()
  love2d.did_setup = false
end

---Capture vim.health calls for assertion
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

---Find a captured entry by type and partial msg match
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

describe("health check", function()
  before_each(function()
    reset_setup()
    capture_health()
  end)

  after_each(function()
    restore_health()
  end)

  it("reports error when setup() was not called", function()
    health.check()
    local entry = find_entry("error", "setup")
    assert.is_not_nil(entry)
  end)

  it("reports ok when setup() was called", function()
    love2d.setup({})
    health.check()
    local entry = find_entry("ok", "setup")
    assert.is_not_nil(entry)
  end)

  it("checks Neovim version", function()
    health.check()
    local ok_entry = find_entry("ok", "Neovim")
    local err_entry = find_entry("error", "Neovim")
    -- One of them must exist
    assert.truthy(ok_entry or err_entry)
  end)

  it("checks for LÖVE binary", function()
    health.check()
    local ok_entry = find_entry("ok", "LÖVE")
    local warn_entry = find_entry("warn", "LÖVE")
    assert.truthy(ok_entry or warn_entry)
  end)

  it("checks for lua-language-server", function()
    health.check()
    local ok_entry = find_entry("ok", "lua%-language%-server")
    local warn_entry = find_entry("warn", "lua%-language%-server")
    assert.truthy(ok_entry or warn_entry)
  end)

  it("checks for treesitter lua parser", function()
    health.check()
    local ok_entry = find_entry("ok", "[Tt]reesitter")
    local warn_entry = find_entry("warn", "[Tt]reesitter")
    assert.truthy(ok_entry or warn_entry)
  end)

  it("calls vim.health.start with plugin name", function()
    health.check()
    local entry = find_entry("start", "love2d")
    assert.is_not_nil(entry)
  end)

  it("uses custom path_to_love_bin after setup", function()
    love2d.setup({ path_to_love_bin = "/custom/path/love" })
    health.check()
    local ok_entry = find_entry("ok", "/custom/path/love")
    local warn_entry = find_entry("warn", "/custom/path/love")
    assert.truthy(ok_entry or warn_entry)
  end)
end)
