local config = {}

config.defaults = {
  path_to_love_bin = "love",
  path_to_love_library = vim.fn.globpath(vim.o.runtimepath, "love2d/library"),
  path_to_luasocket_library = vim.fn.globpath(vim.o.runtimepath, "luasocket/library"),
  restart_on_save = false,
  debug_window_opts = nil,
  identify_love_projects = true,
}

---@class options
---@field path_to_love_bin? string: The path to the Love2D executable
---@field path_to_love_library? string: The path to the Love2D library. Set to "" to disable LSP
---@field path_to_luasocket_library? string: The path to the LuaSocket library. Set to "" to disable LuaSocket LSP
---@field restart_on_save? boolean: Restart Love2D when a file is saved
---@field debug_window_opts? vim.api.keyset.win_config: Create split window with Love2D terminal output
---@field identify_love_projects? boolean: Automatically setup LSP only in detected Love2D projects
config.options = {}

---Detect if current directory is a Love2D project
---@return boolean: true if Love2D project detected
local function is_love2d_project()
  -- Check for common Love2D base file
  if vim.fn.filereadable("main.lua") == 1 then
    return true
  end

  -- Check if any Lua file contains a Love2D function call
  local files = vim.fn.glob("*.lua", false, true)
  for _, file in ipairs(files) do
    local content = vim.fn.readfile(file)

    for _, line in ipairs(content) do
      if line:match("love%.") then
        return true
      end
    end
  end

  return false
end

---Validate library path exists and is readable
---@param path string: Path to validate
---@param name string: Name of the library for error messages
---@return boolean: true if path is valid
local function validate_library_path(path, name)
  if not path or path == "" then
    return false
  end

  local expanded_path = vim.fn.expand(path)
  if vim.fn.isdirectory(expanded_path) == 0 then
    vim.notify(
      string.format("Love2D: %s library path '%s' does not exist or is not accessible", name, expanded_path),
      vim.log.levels.ERROR
    )
    return false
  end

  return true
end

---Setup the LSP for love2d using vim.lsp.config with proper merging
---@param love_library_path string: Path to the Love2D library
---@param luasocket_library_path? string: Path to the LuaSocket library
local function setup_lsp(love_library_path, luasocket_library_path)
  -- Validate inputs
  if not love_library_path or love_library_path == "" then
    vim.notify("Love2D: Cannot setup LSP without a valid Love2D library path", vim.log.levels.ERROR)
    return
  end

  -- Get current lua_ls configuration if it exists
  local current_config = vim.lsp.config.lua_ls or {}
  local existing_settings = current_config.settings or {}
  local existing_lua = existing_settings.Lua or {}
  local existing_workspace = existing_lua.workspace or {}
  local existing_library = existing_workspace.library or {}

  -- Create new library table that preserves existing libraries
  local new_library = vim.tbl_deep_extend("force", {}, existing_library)

  -- Add Love2D library path
  new_library[love_library_path] = true

  -- Add LuaSocket library path if provided and valid
  if luasocket_library_path and luasocket_library_path ~= "" then
    new_library[luasocket_library_path] = true
  end

  -- Create the complete settings configuration that merges with existing
  local settings = vim.tbl_deep_extend("force", existing_settings, {
    Lua = {
      runtime = {
        version = "Lua 5.1",
      },
      workspace = {
        library = new_library,
        checkThirdParty = false,
      },
    },
  })

  -- Use vim.lsp.config with proper merging
  local ok, err = pcall(function()
    vim.lsp.config("lua_ls", {
      settings = settings,
    })
  end)

  if not ok then
    vim.notify(string.format("Love2D: Failed to configure lua_ls LSP: %s", err), vim.log.levels.ERROR)
  end
end

---Create auto commands for love2d:
--- - Restart on save: Restart Love2D when a file is saved.
local function create_auto_commands()
  if config.options.restart_on_save then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("love2d_restart_on_save", { clear = true }),
      pattern = { "*.lua" },
      callback = function()
        local love2d = require("love2d")
        local path = love2d.find_src_path("")
        if path then
          love2d.stop()
          vim.defer_fn(function()
            love2d.run(path)
          end, 500)
        end
      end,
    })
  end
  -- add here other auto commands ...
end

---Setup the love2d configuration.
---It must be called before running a love2d project.
---
---@param opts? options: config table
config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})

  --- @type boolean
  local valid_love_path = nil
  local valid_luasocket_path = nil

  -- Process Love2D library path with validation
  if config.options.path_to_love_library ~= "" then
    local love_library_path = vim.fn.split(vim.fn.expand(config.options.path_to_love_library), "\n")[1]
    if validate_library_path(love_library_path, "Love2D") then
      valid_love_path = love_library_path
    end
  end

  -- Process LuaSocket library path with validation
  if config.options.path_to_luasocket_library ~= "" then
    local luasocket_library_path = vim.fn.split(vim.fn.expand(config.options.path_to_luasocket_library), "\n")[1]
    if validate_library_path(luasocket_library_path, "LuaSocket") then
      valid_luasocket_path = luasocket_library_path
    end
  end

  -- Set up LSP if we have a valid Love2D library path
  if valid_love_path then
    -- Check if identify_love_projects is enabled and if this is a Love2D project
    if config.options.identify_love_projects then
      if is_love2d_project() then
        vim.notify("Love2D project detected, setting up LSP...", vim.log.levels.INFO)
        setup_lsp(valid_love_path, valid_luasocket_path)
      else
        vim.notify(
          "Love2D library available but no Love2D project detected. Use identify_love_projects = false to always setup LSP.",
          vim.log.levels.WARN
        )
      end
    else
      -- Always setup LSP if auto detection is disabled
      setup_lsp(valid_love_path, valid_luasocket_path)
    end
  end

  create_auto_commands()
end

return config
