local config = {}

config.defaults = {
  path_to_love_bin = "love",
  restart_on_save = false,
  debug_window_opts = nil,
  setup_makeprg = true,
}

---@class options
---@field path_to_love_bin? string: The path to the Love2D executable
---@field restart_on_save? boolean: Restart Love2D when a file is saved
---@field debug_window_opts? table: Create split window with Love2D terminal output
---@field setup_makeprg? boolean: Setup makeprg and errorformat for Love2D projects
config.options = {}

---Setup the LSP for love2d using vim.lsp.config with proper merging
local function setup_lsp()
  vim.notify("Setting up LÖVE LSP...", vim.log.levels.INFO)

  local settings = {
    Lua = {
      runtime = { version = "LuaJIT" }, -- LuaJIT 2.1 == Lua 5.1 semantics
      workspace = { checkThirdParty = false },
    },
  }

  if vim.lsp.config.lua_ls then
    settings = vim.tbl_deep_extend("force", vim.lsp.config.lua_ls.settings or {}, settings)
  end

  -- Merge with existing libraries (vim.tbl_deep_extend doesn't work on lists)
  local libraries = {}
  if vim.lsp.config.lua_ls and vim.lsp.config.lua_ls.settings and vim.lsp.config.lua_ls.settings.Lua.workspace then
    libraries = vim.lsp.config.lua_ls.settings.Lua.workspace.library or {}
  end
  table.insert(libraries, vim.fn.globpath(vim.o.runtimepath, "love2d"))
  table.insert(libraries, vim.fn.globpath(vim.o.runtimepath, "luasocket"))

  ---@diagnostic disable-next-line: undefined-field
  settings.Lua.workspace.library = libraries

  -- Apply settings
  vim.lsp.config("lua_ls", { settings = settings })

  -- Restart lua_ls
  vim.lsp.enable({ "lua_ls" }, false)
  vim.lsp.enable({ "lua_ls" })
end

---Setup makeprg and errorformat for Love2D projects
local function setup_makeprg_and_errorformat()
  -- Set errorformat to parse Love2D error messages
  vim.api.nvim_set_option_value(
    "errorformat",
    "Error:%*[^:]:\\ %f:%l:%m,Error:\\ %f:%l:%m,%f:%l:%m",
    { scope = "local" }
  )
  -- Set makeprg to run Love2D on current directory
  vim.api.nvim_set_option_value("makeprg", "love .", { scope = "local" })
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

  if config.options.setup_makeprg then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("love2d_makeprg_setup", { clear = true }),
      pattern = "lua",
      callback = function()
        local love2d = require("love2d")
        if love2d.is_love2d_project() then
          setup_makeprg_and_errorformat()
        end
      end,
    })
  end
  -- add here other auto commands ...
end

---Setup the love2d configuration.
---It must be called before running a love2d project.
---@param opts? options: config table
config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})
  local love2d = require("love2d")
  if love2d.is_love2d_project() then
    vim.notify("Love2D project detected, enabling love2d.nvim", vim.log.levels.INFO)
    setup_lsp()
    create_auto_commands()
  end
end

return config
