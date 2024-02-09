local love2d = {}

---@class job
---@field id number: job-id returned by vim.fn.jobstart
---@field exit_code number: exit-code intercepted by on_exit callback

---Initialize Love2D with options
---@param opts options: The options to initialize Love2D with
love2d.setup = function(opts)
  require("love2d.config").setup(opts)
end

---Run a Love2D project
---@param path string: The path to the Love2D project
love2d.run = function(path)
  love2d.job = {} -- reset job
  vim.notify("Running LÖVE project at " .. path)
  local cmd = require("love2d.config").options.path_to_love .. " " .. path
  love2d.job.id = vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      love2d.job.exit_code = code
      love2d.job.id = nil
    end,
  })
end

---Stop the running project
love2d.stop = function()
  if not love2d.job.id then
    vim.notify("No LÖVE project running.", vim.log.levels.ERROR)
    return
  end
  vim.notify("Stop LÖVE project")
  vim.fn.jobstop(love2d.job.id)
end

return love2d
