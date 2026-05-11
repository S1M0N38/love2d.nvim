local config = require("love2d.config")
local output = require("love2d.output")

local job = {}

job.state = {
  watching = false,
  restarting = false,
  watch_generation = 0,
}

--------------------------------------------------------------------------------
-- Project state (called by autocmd.lua)
--------------------------------------------------------------------------------

function job.set_project(path_to_love2d_project, path_to_main_lua)
  job.state.path_to_love2d_project = path_to_love2d_project
  job.state.path_to_main_lua = path_to_main_lua
end

---Clear the current LÖVE project paths and stop everything.
---Called by autocmd on LeaveLove2DProject.
function job.clear_project()
  job._stop_watch()
  if job.state.id then
    job.state.restarting = true -- prevent on_exit from double-cleaning
    vim.fn.jobstop(job.state.id)
    job.state.id = nil
  end
  job.state.path_to_love2d_project = nil
  job.state.path_to_main_lua = nil
end

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

---Start the LÖVE process.
function job._start_process()
  if not job.state.path_to_main_lua then
    return
  end
  local src = vim.fn.fnamemodify(job.state.path_to_main_lua, ":h")
  local cmd = config.options.path_to_love_bin .. " " .. src

  local win_opts = config.options.output
  output.start(job.state.path_to_love2d_project, win_opts)

  -- Merge job's own on_exit with output's callbacks
  local out_opts = output.job_opts(win_opts)
  local orig_on_exit = out_opts.on_exit

  job.state.exit_code = nil
  job.state.id = vim.fn.jobstart(cmd, {
    on_stdout = out_opts.on_stdout,
    on_stderr = out_opts.on_stderr,
    on_exit = function(jid, code)
      orig_on_exit(jid, code)
      job.state.exit_code = code
      job.state.id = nil
      if job.state.restarting then
        job.state.restarting = false
      else
        job._stop_watch()
      end
    end,
  })
end

---Stop watch mode (idempotent).
function job._stop_watch()
  job.state.watching = false
  job.state.restarting = false
  job.state.watch_generation = job.state.watch_generation + 1
  pcall(vim.api.nvim_del_augroup_by_name, "love2d_watch")
end

---BufWritePost callback for watch mode.
---Kills the running process and schedules a restart after a debounce delay.
function job._on_save()
  if not job.state.watching then
    return
  end
  if not job.state.path_to_main_lua then
    return
  end

  job.state.restarting = true
  job.state.watch_generation = job.state.watch_generation + 1
  local gen = job.state.watch_generation

  if job.state.id then
    vim.fn.jobstop(job.state.id)
    job.state.id = nil
  end

  vim.defer_fn(function()
    if gen ~= job.state.watch_generation then
      return
    end
    job._start_process()
  end, 300)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---Run the detected LÖVE project once.
function job.run()
  if not job.state.path_to_main_lua then
    vim.notify("No LÖVE project detected", vim.log.levels.WARN, { title = "love2d" })
    return
  end
  if job.state.watching then
    vim.notify("Stop watching first with :Love stop", vim.log.levels.WARN, { title = "love2d" })
    return
  end
  if job.state.id then
    vim.notify("A LÖVE project is already running.", vim.log.levels.WARN, { title = "love2d" })
    return
  end
  local src = vim.fn.fnamemodify(job.state.path_to_main_lua, ":h")
  vim.notify("Running LÖVE project at " .. src, vim.log.levels.INFO, { title = "love2d" })
  job._start_process()
end

---Run the detected LÖVE project with auto-restart on save.
function job.watch()
  if not job.state.path_to_main_lua then
    vim.notify("No LÖVE project detected", vim.log.levels.WARN, { title = "love2d" })
    return
  end
  if job.state.watching then
    vim.notify("Already watching LÖVE project", vim.log.levels.WARN, { title = "love2d" })
    return
  end

  -- Stop any existing process (from a previous :Love run)
  if job.state.id then
    job.state.restarting = true
    vim.fn.jobstop(job.state.id)
    job.state.id = nil
  end

  -- Set up watch state
  job.state.watching = true
  job.state.restarting = false
  job.state.watch_generation = job.state.watch_generation + 1

  vim.api.nvim_create_augroup("love2d_watch", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = "love2d_watch",
    pattern = "*.lua",
    callback = job._on_save,
  })

  -- Start the game
  local src = vim.fn.fnamemodify(job.state.path_to_main_lua, ":h")
  vim.notify("Watching LÖVE project at " .. src, vim.log.levels.INFO, { title = "love2d" })
  job._start_process()
end

---Stop the running LÖVE project and/or watch mode.
function job.stop()
  if not job.state.id and not job.state.watching then
    vim.notify("No LÖVE project running.", vim.log.levels.WARN, { title = "love2d" })
    return
  end
  local was_watching = job.state.watching
  job._stop_watch()
  if job.state.id then
    vim.fn.jobstop(job.state.id)
    job.state.id = nil
  end
  local msg = was_watching and "Stopped watching LÖVE project" or "Stopped LÖVE project"
  vim.notify(msg, vim.log.levels.INFO, { title = "love2d" })
end

---Show info about the current LÖVE project and job state.
function job.info()
  local s = job.state
  if not s.path_to_love2d_project then
    vim.notify("Not in a LÖVE project", vim.log.levels.INFO, { title = "love2d" })
    return
  end
  local name = vim.fn.fnamemodify(s.path_to_love2d_project, ":t")
  local rel = vim.fs.relpath(s.path_to_love2d_project, s.path_to_main_lua or "")
  local status
  if s.watching then
    status = "watching"
  else
    status = s.id and "running" or "stopped"
  end
  local lines = {
    "Project:      " .. name,
    "Entry point:  " .. (rel or s.path_to_main_lua or "?"),
    "Status:       " .. status,
  }
  if s.exit_code ~= nil then
    lines[#lines + 1] = "Exit code:    " .. tostring(s.exit_code)
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "love2d" })
end

return job
