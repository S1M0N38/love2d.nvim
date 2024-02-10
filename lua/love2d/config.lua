local config = {}

config.defaults = {
  path_to_love = "love",
  path_to_love_library = vim.fn.expand("%:p:h:h:h") .. "/love2d/library",
}

---@class options
---@field path_to_love? string: The path to the Love2D executable
---@field path_to_love_library? string: The path to the Love2D library. Set to "" to disable LSP
config.options = {}

---Setup the LSP for love2d using lspconfig
---@param library_path string: The path to the love2d library
local function setup_lsp(library_path)
  local lspconfig_installed, lspconfig = pcall(require, "lspconfig")
  if lspconfig_installed then
    lspconfig.lua_ls.setup({
      settings = {
        Lua = {
          workspace = { library = { library_path } },
        },
      },
    })
  else
    vim.notify("Install lspconfig to setup LSP for love2d", vim.log.levels.ERROR)
  end
end

---Setup the love2d configuration.
---It must be called before running a love2d project.
---@param opts? options: config table
config.setup = function(opts)
  config.options = vim.tbl_deep_extend("force", {}, config.defaults, opts or {})

  if config.options.path_to_love_library ~= "" then
    local library_path = vim.fn.expand(config.options.path_to_love_library)
    if vim.fn.isdirectory(library_path) == 0 then
      vim.notify("The library path does not exist.", vim.log.levels.ERROR)
      return
    end
    setup_lsp(library_path)
  end
end

return config
