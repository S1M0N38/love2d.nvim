---@module 'luassert'

local utils = require("love2d.utils")

describe("utils", function()
  local tmpdirs = {}

  ---Create a temporary directory with files.
  ---Cleanup is handled in after_each.
  local function make_dir(name, files)
    local dir = vim.fn.tempname() .. "_" .. name
    vim.fn.mkdir(dir, "p")
    for fname, content in pairs(files) do
      vim.fn.writefile(vim.split(content, "\n"), dir .. "/" .. fname)
    end
    table.insert(tmpdirs, dir)
    return dir
  end

  after_each(function()
    for _, dir in ipairs(tmpdirs) do
      vim.fn.delete(dir, "rf")
    end
    tmpdirs = {}
  end)

  describe("path_to_love2d_project()", function()
    it("detects conf.lua with love.conf", function()
      local dir = make_dir("love_conf", {
        ["conf.lua"] = "function love.conf(t) t.window.title = 'test' end",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir), vim.fn.resolve(result or ""))
    end)

    it("detects main.lua with love callback", function()
      local dir = make_dir("love_cb", {
        ["main.lua"] = "function love.draw() end",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir), vim.fn.resolve(result or ""))
    end)

    it("detects main.lua with love module usage", function()
      local dir = make_dir("love_mod", {
        ["main.lua"] = "love.graphics.print('hi')",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir), vim.fn.resolve(result or ""))
    end)

    it("detects any .lua file with love callback", function()
      local dir = make_dir("love_any", {
        ["game.lua"] = "function love.update(dt) end",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir), vim.fn.resolve(result or ""))
    end)

    it("returns nil for plain lua project", function()
      local dir = make_dir("plain", {
        ["app.lua"] = "local x = 1\nprint(x)",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.is_nil(result)
    end)

    it("returns nil for empty directory", function()
      local dir = make_dir("empty", {})
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.is_nil(result)
    end)

    it("walks upward to find root from subdirectory", function()
      local dir = make_dir("love_sub", {
        ["conf.lua"] = "function love.conf(t) end",
      })
      local subdir = dir .. "/src"
      vim.fn.mkdir(subdir, "p")
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. subdir)
      local result = utils.path_to_love2d_project()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir), vim.fn.resolve(result or ""))
    end)
  end)

  describe("path_to_main_lua()", function()
    it("finds main.lua next to conf.lua", function()
      local dir = make_dir("main_conf", {
        ["conf.lua"] = "function love.conf(t) end",
        ["main.lua"] = "function love.draw() end",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_main_lua()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir .. "/main.lua"), vim.fn.resolve(result or ""))
    end)

    it("finds main.lua next to .git directory", function()
      local dir = make_dir("main_git", {
        ["main.lua"] = "print('hello')",
      })
      vim.fn.mkdir(dir .. "/.git", "p")
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_main_lua()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir .. "/main.lua"), vim.fn.resolve(result or ""))
    end)

    it("returns nil when no conf.lua or .git", function()
      local dir = make_dir("no_root", {
        ["main.lua"] = "print('orphan')",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_main_lua()
      vim.cmd("cd " .. old_cwd)
      assert.is_nil(result)
    end)

    it("finds main.lua with love callback but no conf.lua or .git", function()
      local dir = make_dir("main_cb_only", {
        ["main.lua"] = "function love.draw() end",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_main_lua()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir .. "/main.lua"), vim.fn.resolve(result or ""))
    end)

    it("returns nil when conf.lua exists but no main.lua", function()
      local dir = make_dir("no_main", {
        ["conf.lua"] = "function love.conf(t) end",
      })
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. dir)
      local result = utils.path_to_main_lua()
      vim.cmd("cd " .. old_cwd)
      assert.is_nil(result)
    end)

    it("walks upward from subdirectory to find root", function()
      local dir = make_dir("main_walk", {
        ["conf.lua"] = "function love.conf(t) end",
        ["main.lua"] = "function love.load() end",
      })
      local subdir = dir .. "/src"
      vim.fn.mkdir(subdir, "p")
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. subdir)
      local result = utils.path_to_main_lua()
      vim.cmd("cd " .. old_cwd)
      assert.are.equal(vim.fn.resolve(dir .. "/main.lua"), vim.fn.resolve(result or ""))
    end)
  end)
end)
