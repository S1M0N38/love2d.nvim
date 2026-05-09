---@diagnostic disable: missing-fields
vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {
    { "nvim-treesitter/nvim-treesitter", branch = "main" },
    { dir = "~/Developer/love2d.nvim", opts = {} },
  },
})

-- You should be able to
--   - Run :LoveRun / :LoveStop
--   - See GLSL strings highlighted (run :TSInstall glsl)
--   - Hover (<S-k>) on love functions and see documentation
