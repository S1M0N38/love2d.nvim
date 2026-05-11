---@module 'luassert'

local function reload_autocmd()
  pcall(vim.api.nvim_del_augroup_by_name, "love2d_autocmd")
  -- Force module reloads so augroup ID is fresh
  for _, mod in ipairs({
    "love2d.autocmd",
    "love2d.job",
    "love2d.output",
    "love2d.events",
    "love2d.utils",
    "love2d.lsp",
    "love2d.config",
    "love2d",
  }) do
    package.loaded[mod] = nil
  end
  return require("love2d.autocmd"), require("love2d.job"), require("love2d.output")
end

describe("autocmd", function()
  local autocmd, job, output_mod
  local original_notify
  local notify_calls

  before_each(function()
    autocmd, job, output_mod = reload_autocmd()
    notify_calls = {}
    original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(notify_calls, { msg = msg })
    end
  end)

  after_each(function()
    vim.notify = original_notify
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_autocmd")
  end)

  describe("setup()", function()
    it("creates augroup love2d_autocmd", function()
      autocmd.setup()
      local ok = pcall(vim.api.nvim_get_autocmds, { group = "love2d_autocmd" })
      assert.is_true(ok)
    end)

    it("subscribes to EnterLove2DProject", function()
      autocmd.setup()
      local cmds = vim.api.nvim_get_autocmds({
        group = "love2d_autocmd",
        event = "User",
        pattern = "EnterLove2DProject",
      })
      assert.is_true(#cmds >= 1)
    end)

    it("subscribes to LeaveLove2DProject", function()
      autocmd.setup()
      local cmds = vim.api.nvim_get_autocmds({
        group = "love2d_autocmd",
        event = "User",
        pattern = "LeaveLove2DProject",
      })
      assert.is_true(#cmds >= 1)
    end)
  end)

  describe("EnterLove2DProject handler", function()
    before_each(function()
      -- Reload fresh modules for each test in this block
      autocmd, job, output_mod = reload_autocmd()
      autocmd.setup()
    end)

    it("updates job state with project paths", function()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "EnterLove2DProject",
        data = {
          path_to_love2d_project = "/project",
          path_to_main_lua = "/project/main.lua",
        },
      })
      assert.are.equal("/project", job.state.path_to_love2d_project)
      assert.are.equal("/project/main.lua", job.state.path_to_main_lua)
    end)

    it("shows notification with project name", function()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "EnterLove2DProject",
        data = {
          path_to_love2d_project = "/path/to/mygame",
          path_to_main_lua = "/path/to/mygame/main.lua",
        },
      })
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("mygame"))
    end)
  end)

  describe("LeaveLove2DProject handler", function()
    before_each(function()
      -- Reload fresh modules for each test in this block
      autocmd, job, output_mod = reload_autocmd()
      autocmd.setup()
      -- Set up some state to verify cleanup
      job.set_project("/project", "/project/main.lua")
    end)

    it("clears job project state", function()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "LeaveLove2DProject",
      })
      assert.is_nil(job.state.path_to_love2d_project)
      assert.is_nil(job.state.path_to_main_lua)
    end)

    it("closes output panel", function()
      output_mod.append({ "some output" })
      assert.is_not_nil(output_mod.buf)
      vim.api.nvim_exec_autocmds("User", {
        pattern = "LeaveLove2DProject",
      })
      assert.is_nil(output_mod.buf)
    end)

    it("shows notification", function()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "LeaveLove2DProject",
      })
      assert.are.equal(1, #notify_calls)
      assert.is_truthy(notify_calls[1].msg:match("Left"))
    end)
  end)
end)
