<h1 align="center">💙 LÖVE 2D ❤️</h1>

<p align="center">
  <a href="https://github.com/S1M0N38/love2d.nvim/releases">
    <img alt="Release" src="https://img.shields.io/github/v/release/S1M0N38/love2d.nvim?style=for-the-badge"/>
  </a>
</p>

______________________________________________________________________

## 💡 Idea

I want to experiment with [LÖVE](https://love2d.org/). After reading this [Reddit post](https://www.reddit.com/r/neovim/comments/1727alu/anyone_actively_using_love2d_with_neovim_and/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button) I've realized that it's not so easy to get started with LÖVE and Neovim. Maybe the trickest part is to get LSP working with LÖVE. It's just one line in the LSP but it's usually a very niche thing and I cannot find may examples about; moreover, the `${3rd}` libraries will be [deprecated](https://github.com/LuaLS/lua-language-server/discussions/1950#discussion-4900461) in favor of Addons.

Start and stop the game directly from Neovim (with keybindings) it's also quite handy. So I decied to pack these functionalities (LSP LÖVE config and game start/stop) in a dead simple plugin (so simple that It can be barely consider a plugin).

However I think that providing this simple codebase to explore can be a good introduction to Neovim plugins innter workings. People using LÖVE know Lua so the language barrier boils down to Neovim specific api.

## ⚡️ Requirements

- Neovim >= **0.9**
- [LÖVE](https://www.love2d.org/)
- `lua_ls` configured with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (optional)

## 📦 Installation

```lua
-- using lazy.nvim
{
  "S1M0N38/love2d.nvim",
  cmd = "LoveRun",
  opts = { },
  keys = {
    { "<leader>v", desc = "LÖVE" },
    { "<leader>vv", "<cmd>LoveRun<cr>", desc = "Run LÖVE" },
    { "<leader>vs", "<cmd>LoveStop<cr>", desc = "Stop LÖVE" },
  },
}
```

## 🚀 Usage


<p align="center">
  <em>
    Read the documentation with <a href="https://github.com/S1M0N38/love2d.nvim/blob/main/doc/love2d.txt">`:help love2d`</a>
  </em>
</p>


## 🙏 Acknowledgments

<!-- TODO: Add acknowledgments -->

This very README is a copycat of [lazy.nvim](https://github.com/folke/lazy.nvim) README.
