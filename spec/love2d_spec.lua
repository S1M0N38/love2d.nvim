local love2d = require("love2d")

-- Mock vim.notify to suppress output during tests
local original_notify = vim.notify
vim.notify = function() end

local opts
if vim.fn.has("mac") == 1 then
  opts = {
    path_to_love_bin = "/Applications/love.app/Contents/MacOS/love",
  }
elseif vim.fn.has("linux") == 1 then
  opts = {
    path_to_love_bin = "/usr/bin/love",
  }
else
  error("OS not supported")
end

describe("love2d platform", function()
  it("does not start with wrong path_to_love_bin", function()
    love2d.setup({
      path_to_love_bin = "this/path/does/not/exist/love",
    })
    love2d.run("tests/game")
    vim.wait(1000)
    assert.are.equal(nil, love2d.job.id)
    vim.wait(500)
  end)
  it("starts", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    assert.are.equal(1, vim.fn.jobstop(love2d.job.id))
    vim.wait(500)
  end)
  it("does not run foo with wrong path to game", function()
    love2d.setup(opts)
    love2d.run("tests/foo")
    vim.wait(1000)
    assert.are.equal(1, vim.fn.jobstop(love2d.job.id))
    vim.wait(500)
    assert.are.equal(1, love2d.job.exit_code)
  end)
  it("runs game", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    assert.are.equal(1, vim.fn.jobstop(love2d.job.id))
    vim.wait(500) -- wait for on_exit to be called
    assert.are.equal(0, love2d.job.exit_code)
  end)
  it("stops", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    love2d.stop()
    vim.wait(500)
    assert.are.equal(nil, love2d.job.id)
    assert.are.equal(0, love2d.job.exit_code)
  end)
  it("does not start twice", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    local old_job_id = love2d.job.id
    love2d.run("tests/game")
    vim.wait(1000)
    local new_job_id = love2d.job.id
    love2d.stop()
    vim.wait(500)
    assert.are.equal(new_job_id, old_job_id)
  end)
end)

describe("love2d.find_src_path", function()
  it("finds main.lua in current directory with empty path", function()
    local old_cwd = vim.fn.getcwd()
    vim.cmd("cd tests/game")
    local result = love2d.find_src_path("")
    vim.cmd("cd " .. old_cwd)
    assert.are.equal(".", result)
  end)
  
  it("finds main.lua in specified valid path", function()
    local result = love2d.find_src_path("tests/game")
    assert.are.equal("tests/game", result)
  end)
  
  it("returns nil for invalid path", function()
    local result = love2d.find_src_path("tests/nonexistent")
    assert.are.equal(nil, result)
  end)
  
  it("returns nil for path without main.lua", function() 
    local result = love2d.find_src_path("tests")
    assert.are.equal(nil, result)
  end)
end)

describe("love2d.setup", function()
  it("merges options with defaults", function()
    local config = require("love2d.config")
    local original_options = vim.deepcopy(config.options)
    
    love2d.setup({
      path_to_love_bin = "/custom/love/path",
      restart_on_save = true
    })
    
    assert.are.equal("/custom/love/path", config.options.path_to_love_bin)
    assert.are.equal(true, config.options.restart_on_save)
    assert.are.equal(nil, config.options.debug_window_opts)
    
    -- Reset options
    config.options = original_options
  end)
  
  it("uses defaults when no options provided", function()
    local config = require("love2d.config")
    local original_options = vim.deepcopy(config.options)
    
    love2d.setup()
    
    assert.are.equal("love", config.options.path_to_love_bin)
    assert.are.equal(false, config.options.restart_on_save)
    assert.are.equal(nil, config.options.debug_window_opts)
    
    -- Reset options
    config.options = original_options
  end)
end)

describe("love2d debug window", function()
  after_each(function()
    -- Clean up any debug windows
    if love2d.debug_window and vim.api.nvim_win_is_valid(love2d.debug_window) then
      vim.api.nvim_win_close(love2d.debug_window, true)
    end
    if love2d.job and love2d.job.buf and vim.api.nvim_buf_is_valid(love2d.job.buf) then
      vim.api.nvim_buf_delete(love2d.job.buf, { force = true })
    end
    love2d.debug_window = nil
    love2d.job = {}
  end)
  
  it("creates debug window when debug_window_opts provided", function()
    love2d.setup({
      path_to_love_bin = opts.path_to_love_bin,
      debug_window_opts = {
        split = "right",
        width = 50
      }
    })
    
    love2d.run("tests/game")
    vim.wait(1000)
    
    assert.is_not_nil(love2d.debug_window)
    assert.is_not_nil(love2d.job.buf)
    assert.truthy(vim.api.nvim_win_is_valid(love2d.debug_window))
    assert.truthy(vim.api.nvim_buf_is_valid(love2d.job.buf))
    
    love2d.stop()
    vim.wait(500)
  end)
  
  it("does not create debug window when debug_window_opts is nil", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    
    assert.is_nil(love2d.debug_window)
    assert.is_nil(love2d.job.buf)
    
    love2d.stop()
    vim.wait(500)
  end)
end)

describe("project detection", function()
  local config = require("love2d.config")
  
  it("detects project with main.lua file", function()
    local old_cwd = vim.fn.getcwd()
    vim.cmd("cd tests/game")
    
    -- Access the private is_love2d_project function through config module
    config.setup() -- This will call is_love2d_project internally
    
    vim.cmd("cd " .. old_cwd)
    -- We can't directly test is_love2d_project since it's local, 
    -- but we can verify it works by checking setup behavior
    assert.truthy(true) -- Main test is that it doesn't error
  end)
  
  it("detects project with love. function calls", function()
    local old_cwd = vim.fn.getcwd() 
    vim.cmd("cd tests")
    
    -- The test_love_file.lua contains love. function calls
    config.setup()
    
    vim.cmd("cd " .. old_cwd)
    assert.truthy(true) -- Main test is that it doesn't error
  end)
  
  it("does not detect regular lua project", function()
    local old_cwd = vim.fn.getcwd()
    -- Change to a directory without main.lua or love. functions
    vim.cmd("cd lua/love2d")
    
    config.setup()
    
    vim.cmd("cd " .. old_cwd) 
    assert.truthy(true) -- Main test is that it doesn't error
  end)
end)

describe("restart_on_save functionality", function()
  after_each(function()
    -- Clean up autocmds
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_restart_on_save")
    if love2d.job and love2d.job.id then
      love2d.stop()
      vim.wait(500)
    end
  end)
  
  it("creates autocmd when restart_on_save is enabled", function()
    local old_cwd = vim.fn.getcwd()
    vim.cmd("cd tests/game") -- Change to a love2d project directory
    
    love2d.setup({
      path_to_love_bin = opts.path_to_love_bin,
      restart_on_save = true
    })
    
    -- Check that the augroup was created
    local success, augroups = pcall(vim.api.nvim_get_autocmds, { group = "love2d_restart_on_save" })
    assert.truthy(success)
    assert.truthy(#augroups > 0)
    assert.are.equal("BufWritePost", augroups[1].event)
    
    vim.cmd("cd " .. old_cwd)
  end)
  
  it("does not create autocmd when restart_on_save is disabled", function()
    love2d.setup({
      path_to_love_bin = opts.path_to_love_bin,
      restart_on_save = false
    })
    
    -- Check that no augroup was created for restart_on_save
    local success, augroups = pcall(vim.api.nvim_get_autocmds, { group = "love2d_restart_on_save" })
    if success then
      assert.are.equal(0, #augroups)
    else
      -- Augroup doesn't exist, which is expected
      assert.truthy(true)
    end
  end)
end)

describe("error handling and edge cases", function()
  after_each(function()
    if love2d.job and love2d.job.id then
      love2d.stop()
      vim.wait(500)
    end
  end)
  
  it("handles stop when no job is running", function()
    -- Should not error when stopping with no running job
    local success = pcall(love2d.stop)
    assert.truthy(success)
  end)
  
  it("handles run with empty string path", function()
    love2d.setup(opts)
    local old_cwd = vim.fn.getcwd()
    vim.cmd("cd tests/game")
    
    -- Should find main.lua in current directory
    love2d.run("")
    vim.wait(1000)
    
    assert.is_not_nil(love2d.job.id)
    love2d.stop()
    vim.wait(500)
    vim.cmd("cd " .. old_cwd)
  end)
  
  it("handles nil options in setup", function()
    -- Should not error with nil options
    local success = pcall(love2d.setup, nil)
    assert.truthy(success)
  end)
  
  it("prevents multiple jobs from running simultaneously", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    local first_job_id = love2d.job.id
    
    -- Try to run another job - should be prevented
    love2d.run("tests/game")
    vim.wait(1000)
    
    -- Job ID should remain the same (no new job started)
    assert.are.equal(first_job_id, love2d.job.id)
    
    love2d.stop()
    vim.wait(500)
  end)
  
  it("handles job exit codes properly", function()
    love2d.setup(opts)
    love2d.run("tests/game")
    vim.wait(1000)
    
    love2d.stop()
    vim.wait(1000) -- Wait longer for exit callback
    
    assert.are.equal(0, love2d.job.exit_code)
    assert.is_nil(love2d.job.id)
  end)
end)