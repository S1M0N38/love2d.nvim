local love2d = {}

---@class job
---@field id number: job-id returned by vim.fn.jobstart
---@field exit_code number: exit-code intercepted by on_exit callback

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
	local enable_nvim_term = require("love2d.config").options.nvim_term_buff

	local _o = {
    on_exit = function(_, code)
      love2d.job.exit_code = code
      love2d.job.id = nil
    end,
  }

	if enable_nvim_term then

		if not love2d.job.buf then
			love2d.job.buf = vim.api.nvim_create_buf(true, true)


			love2d.job.win = vim.api.nvim_open_win(love2d.job.buf, false,	{
				split = "below",
			})

			love2d.job.chan = vim.api.nvim_open_term(love2d.job.buf, {})
		end

		vim.api.nvim_create_autocmd("BufWipeout", {
			buffer = love2d.job.buf,
			callback = function()
				if love2d.job.id then
					vim.fn.jobstop(love2d.job.id)
				end
				love2d.job.id = nil
				love2d.job.chan = nil
				love2d.job.buf = nil
				love2d.job.win = nil
			end
		})


		vim.bo[love2d.job.buf].filetype = 'terminal'
		if vim.treesitter then
			vim.treesitter.stop(love2d.job.buf)
		end
		vim.api.nvim_clear_autocmds({ buffer = love2d.job.buf })

		_o.pty = true
		_o.on_stdout = function(_, data)
			if love2d.job.chan ~= nil and love2d.job.buf and vim.api.nvim_buf_is_valid(love2d.job.buf) and vim.api.nvim_buf_is_loaded(love2d.job.buf) then
				pcall(vim.api.nvim_chan_send, love2d.job.chan, table.concat(data, "\n"))
			end
		end
		_o.on_exit = function(_, code)
			if love2d.job.chan ~= nil and love2d.job.buf and vim.api.nvim_buf_is_valid(love2d.job.buf) and vim.api.nvim_buf_is_loaded(love2d.job.buf) then
				pcall(vim.api.nvim_chan_send, love2d.job.chan, '\r\n[Process exited with code: ' .. tostring(code) .. ']')
			end
			love2d.job.exit_code = code
			if love2d.job.id then
				vim.fn.jobstop(love2d.job.id)
			end
			love2d.job.id = nil
			love2d.job.chan = nil
			love2d.job.buf = nil
			love2d.job.win = nil
		end
	end

  love2d.job.id = vim.fn.jobstart(cmd, _o)
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

return love2d
