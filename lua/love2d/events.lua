local utils = require("love2d.utils")

local events = {}

local was_in_project = false
local augroup = vim.api.nvim_create_augroup("love2d_events", { clear = true })

local function check()
  local root = utils.path_to_love2d_project()
  local in_project = root ~= nil

  if not was_in_project and in_project then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "LoveProjectEnter",
      data = {
        path_to_love2d_project = root,
        path_to_main_lua = utils.path_to_main_lua(),
      },
    })
  elseif was_in_project and not in_project then
    vim.api.nvim_exec_autocmds("User", {
      pattern = "LoveProjectLeave",
      data = {
        path_to_love2d_project = nil,
        path_to_main_lua = nil,
      },
    })
  end

  was_in_project = in_project
end

function events.setup()
  vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "BufEnter" }, {
    group = augroup,
    callback = check,
    desc = "Detect LÖVE project enter/leave",
  })
  check()
end

return events
