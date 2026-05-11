---@module 'luassert'

describe("events", function()
  local events
  local notify_calls
  local original_notify

  local function reload_events()
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_events")
    for _, mod in ipairs({ "love2d.events", "love2d.utils" }) do
      package.loaded[mod] = nil
    end
    events = require("love2d.events")
  end

  before_each(function()
    notify_calls = {}
    original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(notify_calls, { msg = msg, level = level })
    end
    reload_events()
  end)

  after_each(function()
    vim.notify = original_notify
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_events")
  end)

  describe("setup()", function()
    it("creates augroup love2d_events", function()
      events.setup()
      local ok = pcall(vim.api.nvim_get_autocmds, { group = "love2d_events" })
      assert.is_true(ok)
    end)

    it("creates autocmds for VimEnter, DirChanged, BufEnter", function()
      events.setup()
      local cmds = vim.api.nvim_get_autocmds({ group = "love2d_events" })
      local events_found = {}
      for _, cmd in ipairs(cmds) do
        if type(cmd.event) == "string" then
          events_found[cmd.event] = true
        elseif type(cmd.event) == "table" then
          for _, e in ipairs(cmd.event) do
            events_found[e] = true
          end
        end
      end
      assert.is_truthy(events_found["VimEnter"])
      assert.is_truthy(events_found["DirChanged"])
      assert.is_truthy(events_found["BufEnter"])
    end)
  end)

  describe("enter/leave detection", function()
    local captured_user_events
    local tmpdirs = {}

    local function make_dir(name, files)
      local dir = vim.fn.tempname() .. "_" .. name
      vim.fn.mkdir(dir, "p")
      for fname, content in pairs(files) do
        vim.fn.writefile(vim.split(content, "\n"), dir .. "/" .. fname)
      end
      table.insert(tmpdirs, dir)
      return dir
    end

    before_each(function()
      captured_user_events = {}
      -- Capture User autocmd events fired by events.check()
      vim.api.nvim_create_autocmd("User", {
        pattern = { "EnterLove2DProject", "LeaveLove2DProject" },
        callback = function(ev)
          table.insert(captured_user_events, {
            pattern = ev.match,
            data = ev.data,
          })
        end,
      })
    end)

    after_each(function()
      -- Restore cwd
      vim.cmd("cd " .. vim.fn.getcwd())
      -- Clean temp dirs
      for _, dir in ipairs(tmpdirs) do
        vim.fn.delete(dir, "rf")
      end
      tmpdirs = {}
    end)

    it("fires EnterLove2DProject when entering a LÖVE project", function()
      local dir = make_dir("enter_test", {
        ["conf.lua"] = "function love.conf(t) end",
      })
      reload_events()
      events.setup()
      -- Now cd into the LÖVE project directory
      vim.cmd("cd " .. dir)
      -- Manually trigger check (BufEnter would do this)
      -- events.setup() already called check() from cwd, but we cd'd after
      -- So we need to trigger a re-check. We'll fire BufEnter to simulate.
      vim.api.nvim_exec_autocmds("BufEnter", {})
      -- Should have fired EnterLove2DProject
      local found = false
      for _, e in ipairs(captured_user_events) do
        if e.pattern == "EnterLove2DProject" then
          found = true
          assert.is_not_nil(e.data)
          assert.are.equal(vim.fn.resolve(dir), vim.fn.resolve(e.data.path_to_love2d_project))
        end
      end
      assert.is_true(found)
    end)

    it("fires LeaveLove2DProject when leaving a LÖVE project", function()
      local dir = make_dir("leave_test", {
        ["conf.lua"] = "function love.conf(t) end",
      })
      local plain_dir = make_dir("plain_leave", {
        ["app.lua"] = "local x = 1",
      })
      reload_events()
      -- Start in the LÖVE project
      vim.cmd("cd " .. dir)
      events.setup()
      -- Now leave to a plain directory
      vim.cmd("cd " .. plain_dir)
      vim.api.nvim_exec_autocmds("BufEnter", {})
      -- Should have fired LeaveLove2DProject
      local found = false
      for _, e in ipairs(captured_user_events) do
        if e.pattern == "LeaveLove2DProject" then
          found = true
        end
      end
      assert.is_true(found)
    end)

    it("does not fire EnterLove2DProject twice when staying in same project", function()
      local dir = make_dir("stay_test", {
        ["conf.lua"] = "function love.conf(t) end",
      })
      reload_events()
      vim.cmd("cd " .. dir)
      events.setup()
      -- Count enter events so far
      local enter_count = 0
      for _, e in ipairs(captured_user_events) do
        if e.pattern == "EnterLove2DProject" then
          enter_count = enter_count + 1
        end
      end
      -- Trigger another check (simulating BufEnter while staying in project)
      vim.api.nvim_exec_autocmds("BufEnter", {})
      -- Enter count should not have increased
      local new_enter_count = 0
      for _, e in ipairs(captured_user_events) do
        if e.pattern == "EnterLove2DProject" then
          new_enter_count = new_enter_count + 1
        end
      end
      assert.are.equal(enter_count, new_enter_count)
    end)
  end)
end)
