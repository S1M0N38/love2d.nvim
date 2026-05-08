local utils = {}

---Display a notification with the love2d title
---@param msg string
---@param level? integer vim.log.levels.*
function utils.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "love2d" })
end

--- LÖVE-specific names used for project detection.
--- Callbacks: `function love.X` definitions unique to LÖVE games.
--- Modules: `love.X.` namespaces unique to the LÖVE framework.
local CALLBACKS = vim.split(
  [[load update draw keypressed keyreleased mousepressed mousereleased
    focus quit resize textinput errorhandler errhand directorydropped
    filedropped joystickadded joystickremoved gamepadpressed
    gamepadreleased touchpressed touchreleased touchmoved wheelmoved]],
  "%s+"
)
local MODULES = vim.split(
  [[graphics window audio filesystem timer mouse keyboard joystick touch
    physics system event math data thread sound image video font]],
  "%s+"
)

--- Check if lines contain `function love.X` for any known callback.
---@param lines string[]
---@return boolean
local function has_love_callback(lines)
  for _, line in ipairs(lines) do
    for _, cb in ipairs(CALLBACKS) do
      if line:match("function love%." .. cb) then
        return true
      end
    end
  end
  return false
end

--- Check if lines contain `love.X.` for any known module.
---@param lines string[]
---@return boolean
local function has_love_module(lines)
  for _, line in ipairs(lines) do
    for _, mod in ipairs(MODULES) do
      if line:match("love%." .. mod .. "%.") then
        return true
      end
    end
  end
  return false
end

---Detect if current directory is a LÖVE project.
---Uses a tiered detection strategy:
---  1. conf.lua with love.conf (highest specificity, near-zero false positives)
---  2. main.lua with LÖVE callback definitions (very specific)
---  3. main.lua with LÖVE module usage (good specificity)
---  4. Any root-level .lua file with LÖVE callback definitions (multi-file projects)
---@return boolean
function utils.is_love2d_project()
  -- Tier 1: conf.lua with love.conf function definition.
  -- This pattern is unique to LÖVE — no other Lua framework uses it.
  if vim.fn.filereadable("conf.lua") == 1 then
    local lines = vim.fn.readfile("conf.lua")
    for _, line in ipairs(lines) do
      if line:match("function love%.conf") then
        return true
      end
    end
  end

  -- Tier 2 & 3: main.lua with LÖVE callbacks or module usage.
  if vim.fn.filereadable("main.lua") == 1 then
    local lines = vim.fn.readfile("main.lua")
    if has_love_callback(lines) or has_love_module(lines) then
      return true
    end
  end

  -- Tier 4: Any root-level .lua file with LÖVE callback definitions.
  -- Catches multi-file projects where main.lua just does require("src.main").
  local files = vim.fn.glob("*.lua", false, true)
  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      local lines = vim.fn.readfile(file)
      if has_love_callback(lines) then
        return true
      end
    end
  end

  return false
end

return utils
