---@meta _

---# Type definitions for love2d.nvim

---Job handle for a running LÖVE process
---@class Love2D.Job
---@field id? integer job-id returned by vim.fn.jobstart
---@field exit_code? integer exit-code intercepted by on_exit callback
---@field buf? integer buffer used for debug window output
---@field augroup? integer augroup id for debug window autocmds

---Configuration for love2d.nvim
---@class Love2D.Config
---@field path_to_love_bin? string Path to the LÖVE executable
---@field restart_on_save? boolean Restart LÖVE when a Lua file is saved
---@field debug_window_opts? table Window configuration for debug output split

-- lua/love2d/utils.lua --------------------------------------------------------

---Shared utilities for love2d.nvim
---@class Love2D.Utils

-- Internal-use functions (available on module table but not part of stable API):
--   love2d.find_src_path(path) — see lua/love2d/init.lua
--   love2d.is_love2d_project() — see lua/love2d/init.lua

-- TODO: Add Love2D.Plugin class when module organization stabilizes (V3 refactor)
