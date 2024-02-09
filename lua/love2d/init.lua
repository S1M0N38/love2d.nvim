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
  vim.notify("Running Love2D project at " .. path, vim.log.levels.INFO)
  local cmd = require("love2d.config").options.path_to_love .. " " .. path
  love2d.job.id = vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      vim.print("Love2D exited with code " .. code)
      love2d.job.exit_code = code
    end,
  })
end

return love2d
