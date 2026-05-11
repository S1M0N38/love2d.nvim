local autocmd = {}

local job = require("love2d.job")
local output = require("love2d.output")
local augroup = vim.api.nvim_create_augroup("love2d_autocmd", { clear = true })

---Setup autocmds for love2d.nvim.
---Subscribes to EnterLove2DProject / LeaveLove2DProject User events
---and shows notifications.
function autocmd.setup()
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "EnterLove2DProject",
    desc = "Notify when entering a LÖVE project",
    callback = function(ev)
      local path = ev.data and ev.data.path_to_love2d_project
      local main = ev.data and ev.data.path_to_main_lua
      -- Update job module state
      if path and main then
        job.set_project(path, main)
      end
      -- Notify user
      local name = path and vim.fn.fnamemodify(path, ":t") or "unknown"
      local lines = { "LÖVE project: " .. name }
      if main and path then
        local rel = vim.fs.relpath(path, main)
        lines[2] = "Entry point:  " .. (rel or main)
      end
      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "love2d" })
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "LeaveLove2DProject",
    desc = "Clean up when leaving a LÖVE project",
    callback = function()
      job.clear_project()
      output.close()
      vim.notify("Left LÖVE project", vim.log.levels.INFO, { title = "love2d" })
    end,
  })
end

return autocmd
