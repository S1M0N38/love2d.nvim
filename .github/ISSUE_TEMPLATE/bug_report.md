---
name: Bug report
about: Create a report to help us improve
title: 'bug: [replace these brackets with the actual title]'
labels: bug
assignees: S1M0N38
---

**Versions**

- *OS* \[e.g. macOS 15.1\]
- *Neovim* \[e.g. 0.11.2\]
- *Plugin* \[e.g. 2.0.0\]


## Test with `minimal.lua`

>[!IMPORTANT]
> Please do not skip this step. For most users, issues occur because of their Neovim configuration.

1. Create the file `repro.lua` with the following content

```lua
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

-- Add additional setup here ...
```


2. Open your love2d `main.lua` using `repro.lua` as config:

```
nvim -u repro.lua main.lua
```

> [!TIP]
> Alternatively, you can clone this repository, navigate to the `tests/game` directory and run `nvim -u repro.lua main.lua`*

3. Reproduce the bug

4. All the artifacts will be stored in the `.repro` directory, you can share them with us (e.g. logs, states, etc.)

## Describe the bug

A clear and concise description of what the bug is and the expected behavior.

## Reproduce the bug

Write down the steps to reproduce the behavior:

1. Go to '...'
1. Click on '....'
1. Scroll down to '....'
1. See error

You can also include screenshot (simply drag and drop image or video in this text area)
