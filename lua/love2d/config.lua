local config = {}

config.defaults = {
  path_to_love_bin = "love",
  restart_on_save = false,
  debug_window_opts = nil,
}

---@type Love2D.Config
config.options = {}

---Inject submodule library paths (love2d, luasocket) into lua_ls workspace.library.
local function setup_lsp_libraries()
  local existing = {}
  local cfg = vim.lsp.config.lua_ls
  if
    cfg
    and cfg.settings
    and cfg.settings.Lua
    and cfg.settings.Lua.workspace
    and cfg.settings.Lua.workspace.library
  then
    existing = vim.list_slice(cfg.settings.Lua.workspace.library)
  end

  -- Resolve submodule paths from runtimepath
  local libs = { "love2d", "luasocket" }
  for _, name in ipairs(libs) do
    local path = vim.fn.globpath(vim.o.runtimepath, name, false, true)
    if path and path[1] then
      table.insert(existing, path[1])
    end
  end

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        workspace = {
          library = existing,
        },
      },
    },
  })
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

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("love2d_compiler_setup", { clear = true }),
    pattern = "lua",
    callback = function()
      local utils = require("love2d.utils")
      if utils.is_love2d_project() then
        vim.cmd.compiler("love")
      end
    end,
  })
  -- add here other auto commands ...
end

---Setup the love2d configuration.
---It must be called before running a love2d project.
---@param opts? Love2D.Config config table
config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})
  local love2d = require("love2d")
  if love2d.is_love2d_project() then
    vim.notify("Love2D project detected, enabling love2d.nvim", vim.log.levels.INFO)
    setup_lsp_libraries()
    vim.lsp.enable("lua_ls")
    create_auto_commands()
  end
end

return config
