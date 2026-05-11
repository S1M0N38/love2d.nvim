local utils = {}

--- LÖVE-specific names used for project detection.
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

---Check if a directory looks like a LÖVE project root.
---@param dir string Absolute path.
---@return boolean
local function is_love2d_root(dir)
  -- conf.lua with love.conf
  local conf = dir .. "/conf.lua"
  if vim.fn.filereadable(conf) == 1 then
    for _, line in ipairs(vim.fn.readfile(conf)) do
      if line:match("function love%.conf") then
        return true
      end
    end
  end

  -- main.lua with LÖVE callbacks or module usage.
  local main = dir .. "/main.lua"
  if vim.fn.filereadable(main) == 1 then
    local lines = vim.fn.readfile(main)
    if has_love_callback(lines) or has_love_module(lines) then
      return true
    end
  end

  -- Any .lua file with LÖVE callback definitions.
  local files = vim.fn.glob(dir .. "/*.lua", false, true)
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

function utils.path_to_love2d_project()
  local dir = vim.fn.getcwd()
  while dir do
    if is_love2d_root(dir) then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      return
    end
    dir = parent
  end
end

function utils.path_to_main_lua()
  local dir = vim.fn.getcwd()
  while dir do
    if vim.fn.filereadable(dir .. "/conf.lua") == 1 or vim.fn.isdirectory(dir .. "/.git") == 1 then
      local main = dir .. "/main.lua"
      if vim.fn.filereadable(main) == 1 then
        return main
      end
      return -- found root but no main.lua — stop walking
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      return
    end
    dir = parent
  end
end

return utils
