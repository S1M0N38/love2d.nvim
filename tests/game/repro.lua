---@diagnostic disable: missing-fields
vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {

    -- Configure treesitter lua and glsl
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "glsl" },
          auto_install = true,
        })
      end,
    },

    -- NOTE: maybe you need to reload the buffer after first time installing
    -- treesitter to make the syntax highlighting work

    -- Configuration for lua_ls
    { "neovim/nvim-lspconfig" },

    -- love2d.nvim
    {
      "S1M0N38/love2d.nvim",
      -- dir = "~/Developer/love2d.nvim", -- if you want to use a local copy of love2d.nvim
      opts = {
        -- configure the path to the love executable
        -- path_to_love_bin = "love",
        --
        -- restart love2d when a file is saved
        -- restart_on_save = false,
        --
        -- setup makeprg and errorformat for :make command (default: true)
        -- setup_makeprg = true,
        --
        -- Open a right split window logging debug messages from love2d
        -- debug_window_opts = {
        --   split = "right",
        -- },
      },
    },
  },
})

-- You should be able to
--  - run the command :LoveRun
--  - run the command :LoveStop
--  - see glsl string correctly highlighted
--  - hover (<S-k>) on love functions and see the documentation
