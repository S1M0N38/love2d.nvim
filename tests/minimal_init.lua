-- Add runtime paths
vim.opt.rtp:append(".")
vim.opt.rtp:append("../plenary.nvim")
vim.opt.rtp:append("../nvim-lspconfig")

-- Load plugins
vim.cmd("runtime! plugin/plenary.vim")

-- Open tests/game/main.lua
-- and attach lua_ls as LSP
vim.lsp.set_log_level("trace")
require("vim.lsp.log").set_format_func(vim.inspect)
require("lspconfig").lua_ls.setup({
  cmd = { "lua-language-server", "--stdio" },
  on_attach = function() end,
})
