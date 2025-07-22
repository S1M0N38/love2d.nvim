local love2d = {}

---@class job
---@field id number: job-id returned by vim.fn.jobstart
---@field exit_code number: exit-code intercepted by on_exit callback

---Options and Initializations for debug window
---@param job_opts table
---@param window_opts table
local function enable_debug_window(job_opts, window_opts)
  if not love2d.job.augroup then
    vim.api.nvim_create_augroup("Love2D", {})
  end

  if not love2d.job.buf then
    love2d.job.buf = vim.api.nvim_create_buf(false, true)

    if not love2d.debug_window then
      love2d.debug_window = vim.api.nvim_open_win(love2d.job.buf, false, window_opts)

      vim.api.nvim_create_autocmd("WinClosed", {
        group = love2d.job.augroup,
        callback = function(args)
          if args.match == tostring(love2d.debug_window) then
            vim.api.nvim_buf_delete(love2d.job.buf, { force = true })
            love2d.debug_window = nil
            love2d.job.buf = nil
            return true
          end
        end,
      })
    end

    vim.api.nvim_win_set_buf(love2d.debug_window, love2d.job.buf)
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = love2d.job.buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = love2d.job.buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = love2d.job.buf })
    vim.api.nvim_set_option_value("number", false, { win = love2d.debug_window })
    vim.api.nvim_set_option_value("relativenumber", false, { win = love2d.debug_window })
  end

  job_opts.on_stdout = function(_, data)
    if love2d.job.buf and vim.api.nvim_buf_is_valid(love2d.job.buf) and vim.api.nvim_buf_is_loaded(love2d.job.buf) then
      local lines = vim.tbl_filter(function(line)
        return line ~= ""
      end, data)
      vim.api.nvim_buf_set_lines(love2d.job.buf, -1, -1, false, lines)
    end
  end

  return job_opts
end

---Find a valid path to the Love2D project
---@param path string: The path to the Love2D project. If "" search for it.
---@return string?: The path to the Love2D project. nil if not found
love2d.find_src_path = function(path)
  local main
  if path == "" then
    main = vim.fn.findfile("main.lua", ".;")
  else
    main = vim.fn.findfile("main.lua", path)
  end
  if main == "" then
    return
  end
  return vim.fn.fnamemodify(main, ":h")
end

---Initialize Love2D with options
---@param opts options: The options to initialize Love2D with
love2d.setup = function(opts)
  require("love2d.config").setup(opts)
end

---Run a Love2D project
---@param path string: The path to the Love2D project
love2d.run = function(path)
  if love2d.job and love2d.job.id then
    vim.notify("A LÖVE project is already running.", vim.log.levels.WARN)
    return
  end
  love2d.job = {} -- reset job
  vim.notify("Running LÖVE project at " .. path)
  local cmd = require("love2d.config").options.path_to_love_bin .. " " .. path

  local job_opts = {
    on_exit = function(_, code)
      love2d.job.exit_code = code
      love2d.job.id = nil
    end,
  }

  local window_opts = require("love2d.config").options.debug_window_opts
  if window_opts then
    job_opts = enable_debug_window(job_opts, window_opts)
  end

  love2d.job.id = vim.fn.jobstart(cmd, job_opts)
end

---Stop the running project
love2d.stop = function()
  if not love2d.job or not love2d.job.id then
    vim.notify("No LÖVE project running.", vim.log.levels.WARN)
    return
  end
  vim.notify("Stop LÖVE project")
  vim.fn.jobstop(love2d.job.id)
end

---Detect if current directory is a Love2D project
---@return boolean: true if Love2D project detected
love2d.is_love2d_project = function()
  -- Check for common Love2D base file
  if vim.fn.filereadable("main.lua") == 1 then
    return true
  end

  -- Check if any Lua file contains a Love2D function call
  local files = vim.fn.glob("*.lua", false, true)
  for _, file in ipairs(files) do
    local content = vim.fn.readfile(file)
    for _, line in ipairs(content) do
      if line:match("love%.") then
        return true
      end
    end
  end

  return false
end

return love2d
