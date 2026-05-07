local M = {}

M.check = function()
  vim.health.start("love2d.nvim")

  -- Setup check
  local love2d = require("love2d")
  if love2d.did_setup then
    vim.health.ok("setup() was called")
  else
    vim.health.error("setup() was not called", "Call require('love2d').setup() in your config.")
  end

  -- Neovim version
  if vim.fn.has("nvim-0.12.2") == 1 then
    vim.health.ok("Neovim >= 0.12.2")
  else
    vim.health.error("Neovim >= 0.12.2 is required", "Current version: " .. tostring(vim.version()))
  end

  -- LÖVE binary
  local config = require("love2d.config")
  local love_bin = config.options.path_to_love_bin or "love"
  if vim.fn.executable(love_bin) == 1 then
    vim.health.ok("LÖVE binary found: `" .. love_bin .. "`")
  else
    vim.health.warn(
      "LÖVE binary not found: `" .. love_bin .. "`",
      "Install LÖVE or set `path_to_love_bin` in setup()."
    )
  end

  -- lua-language-server
  if vim.fn.executable("lua-language-server") == 1 then
    vim.health.ok("lua-language-server found")
  else
    vim.health.warn("lua-language-server not found", "Install lua-language-server for LSP support.")
  end

  -- Treesitter parsers
  local ok, parsers = pcall(vim.treesitter.language.get_lang, "lua")
  if ok and parsers then
    local has_lua = pcall(vim.treesitter.language.inspect, "lua")
    if has_lua then
      vim.health.ok("Treesitter lua parser installed")
    else
      vim.health.warn("Treesitter lua parser not installed", "Run `:TSInstall lua` for syntax highlighting.")
    end
  else
    vim.health.warn("Treesitter lua parser not installed", "Run `:TSInstall lua` for syntax highlighting.")
  end
end

return M
