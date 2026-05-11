---@module 'luassert'

local job = require("love2d.job")
local config = require("love2d.config")

describe("job", function()
  local original_notify
  local notify_calls
  local original_jobstop
  local jobstop_calls
  local jobstart_calls

  before_each(function()
    -- Reset job state
    job.state = {
      watching = false,
      restarting = false,
      watch_generation = 0,
    }
    -- Mock notifications
    notify_calls = {}
    original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(notify_calls, { msg = msg, level = level })
    end
    -- Mock jobstop to track calls without killing real processes
    jobstop_calls = {}
    original_jobstop = vim.fn.jobstop
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstop = function(id)
      table.insert(jobstop_calls, id)
      return 1
    end
    -- Mock jobstart to prevent spawning real processes
    -- Does NOT schedule on_exit (avoids async leaks into later tests)
    jobstart_calls = {}
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(cmd, opts)
      assert.is_true(type(cmd) == "string")
      assert.is_function(opts.on_exit)
      table.insert(jobstart_calls, { cmd = cmd, opts = opts })
      return 99999
    end
    -- Reset config
    config.options = vim.deepcopy(config.defaults)
    -- Clean autocmds
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_watch")
  end)

  after_each(function()
    vim.notify = original_notify
    vim.fn.jobstop = original_jobstop
    vim.fn.jobstart = nil -- restore to original
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_watch")
  end)

  describe("set_project() / clear_project()", function()
    it("sets project paths", function()
      job.set_project("/path/to/project", "/path/to/project/main.lua")
      assert.are.equal("/path/to/project", job.state.path_to_love2d_project)
      assert.are.equal("/path/to/project/main.lua", job.state.path_to_main_lua)
    end)

    it("clears project paths and stops watch", function()
      job.set_project("/path/to/project", "/path/to/project/main.lua")
      job.state.watching = true
      job.clear_project()
      assert.is_nil(job.state.path_to_love2d_project)
      assert.is_nil(job.state.path_to_main_lua)
      assert.is_false(job.state.watching)
    end)

    it("calls jobstop when clearing a running job", function()
      job.state.id = 12345
      job.state.restarting = false
      job.clear_project()
      -- Verify jobstop was called with the right ID
      assert.are.equal(1, #jobstop_calls)
      assert.are.equal(12345, jobstop_calls[1])
      assert.is_nil(job.state.id)
    end)
  end)

  describe("run()", function()
    it("warns when no project detected", function()
      job.state.path_to_main_lua = nil
      job.run()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("No LÖVE project"))
    end)

    it("warns when already watching", function()
      job.state.path_to_main_lua = "/tmp/main.lua"
      job.state.watching = true
      job.run()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("Stop watching"))
    end)

    it("warns when already running", function()
      job.state.path_to_main_lua = "/tmp/main.lua"
      job.state.id = 12345
      job.run()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("already running"))
    end)

    it("starts a process when project is set", function()
      job.set_project("/path/to/project", "/path/to/project/main.lua")
      config.options.path_to_love_bin = "love"
      job.run()
      -- Should have a job ID from mocked jobstart
      assert.is_not_nil(job.state.id)
      assert.are.equal(99999, job.state.id)
      -- Should have notified about running
      assert.is_truthy(notify_calls[1].msg:match("Running"))
      -- Should have called jobstart with correct command
      assert.are.equal(1, #jobstart_calls)
      assert.is_truthy(jobstart_calls[1].cmd:match("love"))
      assert.is_truthy(jobstart_calls[1].cmd:match("project"))
    end)
  end)

  describe("stop()", function()
    it("warns when nothing is running", function()
      job.state.id = nil
      job.state.watching = false
      job.stop()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("No LÖVE project running"))
    end)

    it("kills running job and notifies", function()
      job.state.id = 12345
      job.stop()
      assert.are.equal(1, #jobstop_calls)
      assert.are.equal(12345, jobstop_calls[1])
      assert.is_nil(job.state.id)
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("Stopped"))
    end)

    it("stops watch mode and kills job", function()
      job.state.id = 12345
      job.state.watching = true
      job.stop()
      assert.is_false(job.state.watching)
      assert.is_nil(job.state.id)
      assert.are.equal(1, #jobstop_calls)
      assert.is_truthy(notify_calls[1].msg:match("Stopped watching"))
    end)
  end)

  describe("watch()", function()
    it("warns when no project detected", function()
      job.state.path_to_main_lua = nil
      job.watch()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("No LÖVE project"))
    end)

    it("warns when already watching", function()
      job.state.path_to_main_lua = "/tmp/main.lua"
      job.state.watching = true
      job.watch()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("Already watching"))
    end)

    it("creates BufWritePost autocmd and starts process", function()
      job.set_project("/path/to/project", "/path/to/project/main.lua")
      job.watch()
      assert.is_true(job.state.watching)
      assert.is_not_nil(job.state.id)
      -- Verify the autocmd was created with correct details
      local cmds = vim.api.nvim_get_autocmds({
        group = "love2d_watch",
        event = "BufWritePost",
      })
      assert.are.equal(1, #cmds)
      assert.are.equal("*.lua", cmds[1].pattern)
      -- watch_generation should have been incremented
      assert.are.equal(1, job.state.watch_generation)
    end)

    it("kills existing process before starting watch", function()
      job.set_project("/path/to/project", "/path/to/project/main.lua")
      job.state.id = 12345
      job.watch()
      -- Should have called jobstop on the old process
      assert.are.equal(1, #jobstop_calls)
      assert.are.equal(12345, jobstop_calls[1])
      -- Should have started a new process
      assert.are.equal(99999, job.state.id)
    end)
  end)

  describe("info()", function()
    it("notifies when not in a project", function()
      job.state.path_to_love2d_project = nil
      job.info()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("Not in a LÖVE project"))
    end)

    it("shows project info when in a project", function()
      job.set_project("/path/to/mygame", "/path/to/mygame/main.lua")
      job.info()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("mygame"))
      assert.is_truthy(notify_calls[1].msg:match("stopped"))
    end)

    it("shows running status", function()
      job.set_project("/path/to/mygame", "/path/to/mygame/main.lua")
      job.state.id = 12345
      job.info()
      assert.are.equal(1, #notify_calls)
      -- Should show "running", not "stopped"
      assert.is_falsy(notify_calls[1].msg:match("stopped"))
      assert.is_truthy(notify_calls[1].msg:match("running"))
    end)

    it("shows watching status", function()
      job.set_project("/path/to/mygame", "/path/to/mygame/main.lua")
      job.state.watching = true
      job.info()
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("watching"))
    end)
  end)

  describe("state defaults (on fresh require)", function()
    it("has nil project/id and false watching/restarting", function()
      -- Reload module to get pristine state
      package.loaded["love2d.job"] = nil
      local fresh_job = require("love2d.job")
      assert.is_nil(fresh_job.state.path_to_love2d_project)
      assert.is_nil(fresh_job.state.path_to_main_lua)
      assert.is_nil(fresh_job.state.id)
      assert.is_false(fresh_job.state.watching)
      assert.is_false(fresh_job.state.restarting)
      -- Restore the module reference for other tests
      package.loaded["love2d.job"] = nil
      require("love2d.job")
    end)
  end)
end)
