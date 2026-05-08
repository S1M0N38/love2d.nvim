---@diagnostic disable: missing-fields
vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {
    -- Treesitter: auto-install glsl parser for LÖVE shader highlighting
    -- Requires tree-sitter CLI: npm install -g tree-sitter-cli
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      opts = {
        ensure_installed = { "glsl" },
      },
      config = function(_, opts)
        local TS = require("nvim-treesitter")
        TS.setup(opts)

        -- Install missing parsers (like LazyVim does)
        local installed = TS.get_installed()
        local missing = vim.tbl_filter(function(lang)
          return not vim.tbl_contains(installed, lang)
        end, opts.ensure_installed or {})
        if #missing > 0 then
          TS.install(missing, { summary = true })
        end

        -- Enable highlighting for current and future buffers
        local group = vim.api.nvim_create_augroup("repro_treesitter", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          callback = function(ev)
            pcall(vim.treesitter.start, ev.buf)
          end,
        })
        -- Also attach to already-open buffers
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) then
            pcall(vim.treesitter.start, buf)
          end
        end
      end,
    },

    -- Configure lua_ls command (settings come from lsp/lua_ls.lua)
    {
      "S1M0N38/love2d.nvim",
      init = function()
        vim.lsp.config("lua_ls", {
          cmd = { "lua-language-server" },
        })
      end,
      -- dir = "~/Developer/love2d.nvim", -- if you want to use a local copy of love2d.nvim
      opts = {
        -- path_to_love_bin = "love",
        -- restart_on_save = false,
        -- libraries = { "https://github.com/LuaCATS/love2d", "https://github.com/LuaCATS/luasocket" },
        -- debug_window_opts = { split = "right" },
      },
    },
  },
})

-- You should be able to
--  - run the command :LoveRun
--  - run the command :LoveStop
--  - see glsl string correctly highlighted
--  - hover (<S-k>) on love functions and see the documentation
