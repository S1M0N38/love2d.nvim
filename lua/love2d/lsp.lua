---LSP integration for love2d.nvim.
---Dynamically configures lua_ls when entering/leaving a LÖVE project.
---Uses Neovim's config-chain merge API (vim.lsp.config) to be non-destructive.
---
---Design:
---   - lsp/lua_ls.lua provides the base config (cmd) — zero-config for users.
---   - This module merges love-specific settings (runtime, diagnostics, library)
---     on EnterLove2DProject via vim.lsp.config("lua_ls", { ... }).
---   - workspace.library is read from the resolved config first, then love paths
---     are appended — user paths are never lost.
---   - On LeaveLove2DProject, love library paths are stripped from the config
---     and any running lua_ls client is notified via workspace/didChangeConfiguration.
---   - Static settings (LuaJIT runtime, duplicate-set-field disable, checkThirdParty)
---     are left in place on leave — they're harmless for non-LÖVE Lua.
---   - vim.lsp.enable("lua_ls") is called once in setup() if not already enabled.
---
local lsp = {}

local augroup = vim.api.nvim_create_augroup("love2d_lsp", { clear = true })

---Submodule paths relative to the plugin root. Each contains type definitions
---for lua_ls workspace.library.
local LIBRARY_GLOBS = { "libraries/love2d/library", "libraries/luasocket/library" }

lsp._cached_library_paths = nil

function lsp._resolve_library_paths()
  local paths = {}
  for _, glob in ipairs(LIBRARY_GLOBS) do
    local found = vim.fn.globpath(vim.o.runtimepath, glob, false, true)
    if found and found[1] then
      table.insert(paths, found[1])
    end
  end
  return paths
end

function lsp._get_existing_library()
  local ok, cfg = pcall(function()
    return vim.lsp.config.lua_ls
  end)
  if not ok or not cfg then
    return {}
  end
  local library = cfg
    and cfg.settings
    and cfg.settings.Lua
    ---@diagnostic disable-next-line: undefined-field
    and cfg.settings.Lua.workspace
    ---@diagnostic disable-next-line: undefined-field
    and cfg.settings.Lua.workspace.library
  if library and type(library) == "table" then
    return vim.list_slice(library)
  end
  return {}
end

function lsp._build_settings(library_paths)
  return {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        disable = { "duplicate-set-field" },
      },
      workspace = {
        checkThirdParty = false,
        library = library_paths,
      },
    },
  }
end

function lsp._enable()
  local love_paths = lsp._resolve_library_paths()
  if #love_paths == 0 then
    return
  end

  lsp._cached_library_paths = love_paths

  -- Read existing library and append love paths (preserving user paths).
  local existing = lsp._get_existing_library()
  local merged = vim.list_slice(existing)
  for _, p in ipairs(love_paths) do
    table.insert(merged, p)
  end

  vim.lsp.config("lua_ls", {
    settings = lsp._build_settings(merged),
  })
end

function lsp._disable()
  if not lsp._cached_library_paths then
    return
  end

  -- Build a set of our paths for fast lookup.
  local ours = {}
  for _, p in ipairs(lsp._cached_library_paths) do
    ours[p] = true
  end
  lsp._cached_library_paths = nil

  -- Filter our paths out of the current library list.
  local current = lsp._get_existing_library()
  local filtered = {}
  for _, p in ipairs(current) do
    if not ours[p] then
      table.insert(filtered, p)
    end
  end

  vim.lsp.config("lua_ls", {
    settings = lsp._build_settings(filtered),
  })

  -- Notify any running lua_ls clients so they re-read settings.
  for _, client in ipairs(vim.lsp.get_clients({ name = "lua_ls" })) do
    client:notify("workspace/didChangeConfiguration", {
      settings = client.settings,
    })
  end
end

function lsp.setup()
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "EnterLove2DProject",
    callback = function()
      lsp._enable()
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "LeaveLove2DProject",
    callback = function()
      lsp._disable()
    end,
  })

  -- Enable lua_ls auto-activation (no-op if already enabled by the user).
  vim.lsp.enable("lua_ls")
end

return lsp
