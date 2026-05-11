local love2d = {}

love2d.did_setup = false

love2d.setup = function(opts)
  if love2d.did_setup then
    vim.notify("love2d.nvim is already setup", vim.log.levels.WARN, { title = "love2d" })
    return
  end
  love2d.did_setup = true
  require("love2d.config").setup(opts) -- configure love2d.nvim options
  require("love2d.autocmd").setup() -- configure love2d.nvim autocmds
  require("love2d.events").setup() -- configure love2d.nvim events
  if require("love2d.config").options.lsp then
    require("love2d.lsp").setup() -- configure lua_ls for LÖVE
  end
end

return love2d
