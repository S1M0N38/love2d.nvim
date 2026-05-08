local config = {}

config.defaults = {
  path_to_love_bin = "love",
  restart_on_save = false,
  debug_window_opts = nil,
  libraries = {
    "https://github.com/LuaCATS/love2d",
    "https://github.com/LuaCATS/luasocket",
  },
}

---@type Love2D.Config
config.options = {}

---Derive plugin name from a git URL.
---"https://github.com/LuaCATS/love2d" → "love2d"
---@param url string
---@return string
local function repo_name(url)
  return url:match("([^/]+)%.git$") or url:match("([^/]+)$")
end

---Install LÖVE definition libraries via vim.pack and inject paths into lua_ls.
local function setup_lsp_libraries()
  local libs = config.options.libraries
  if not libs or #libs == 0 then
    return
  end

  -- Install libraries (vim.pack clones if needed, adds to runtimepath)
  vim.pack.add(libs)

  -- Preserve existing lua_ls library paths
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

  -- Resolve installed paths from vim.pack
  for _, url in ipairs(libs) do
    local name = repo_name(url)
    if name then
      local packs = vim.pack.get({ name })
      if packs and packs[1] and packs[1].path then
        table.insert(existing, packs[1].path)
      end
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
