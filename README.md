<h1 align="center">♡&nbsp;&nbsp;LÖVE 2D&nbsp;&nbsp;♡</h1>

<p align="center">
  <a href="https://github.com/S1M0N38/love2d.nvim/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/S1M0N38/love2d.nvim?style=for-the-badge"/>
  </a>
  <a href="https://luarocks.org/modules/S1M0N38/love2d.nvim">
    <img alt="LuaRocks release" src="https://img.shields.io/luarocks/v/S1M0N38/love2d.nvim?style=for-the-badge&color=5d2fbf"/>
  </a>
  <a href="https://www.reddit.com/r/neovim/comments/1aol6nt/love2dnvim">
    <img alt="Reddit post" src="https://img.shields.io/badge/post-reddit?style=for-the-badge&label=Reddit&color=FF5700"/>
  </a>
</p>

______________________________________________________________________

## 💡 Idea

I wanted to experiment with [LÖVE](https://love2d.org/). After reading this [Reddit post](https://www.reddit.com/r/neovim/comments/1727alu/anyone_actively_using_love2d_with_neovim_and), I realized that it's not so easy to get started with LÖVE and Neovim. Perhaps the trickiest part is getting LSP to work with LÖVE. It's just one line in the LSP, but it's usually a very niche thing and I can't find many examples about it; moreover, the `${3rd}` libraries will be [deprecated](https://github.com/LuaLS/lua-language-server/discussions/1950#discussion-4900461) in favor of Addons.

Being able to start and stop the game directly from Neovim (with keybindings) is also quite handy. So I decided to pack these functionalities (LSP LÖVE config and game start/stop) into a dead simple plugin (so simple that it can barely be considered a plugin).

However, I believe that providing this simple codebase to explore can be a good introduction to the inner workings of Neovim plugins. People using LÖVE know Lua, so the language barrier boils down to the Neovim specific API.

## ⚡️ Requirements

- Neovim >= **0.9**
- [LÖVE](https://www.love2d.org/)
- [lua_ls](https://luals.github.io/) configured with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (optional)

## 📦 Installation

```lua
-- using lazy.nvim
{
  "S1M0N38/love2d.nvim",
  cmd = "LoveRun",
  opts = { },
  keys = {
    { "<leader>v", ft = "lua", desc = "LÖVE" },
    { "<leader>vv", "<cmd>LoveRun<cr>", ft = "lua", desc = "Run LÖVE" },
    { "<leader>vs", "<cmd>LoveStop<cr>", ft = "lua", desc = "Stop LÖVE" },
  },
}
```

## 🚀 Usage

Read the documentation with [`:help love2d`](https://github.com/S1M0N38/love2d.nvim/blob/main/doc/love2d.txt)

> Vim/Neovim plugins are usually shipped with :help documentation. Learning how to navigate it is a really valuable skill. If you are not familiar with it, start with `:help` and read the first 20 lines.

## 🙏 Acknowledgments

- [Reddit post](https://www.reddit.com/r/neovim/comments/1727alu/anyone_actively_using_love2d_with_neovim_and) for the idea
- Lua Language Server [LÖVE addon](https://github.com/LuaCATS/love2d)
- My Awesome Plugin [template](https://github.com/S1M0N38/my-awesome-plugin.nvim)
