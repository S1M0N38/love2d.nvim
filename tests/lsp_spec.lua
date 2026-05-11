---@module 'luassert'

local lsp = require("love2d.lsp")

local function stub_resolve(fn)
  local orig = lsp._resolve_library_paths
  lsp._resolve_library_paths = fn
  return orig
end

local function restore_resolve(orig)
  lsp._resolve_library_paths = orig
end

describe("lsp", function()
  local saved_ls_config

  before_each(function()
    -- Reset lsp module state
    lsp._cached_library_paths = nil
    -- Clean up any lsp autocmds
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_lsp")
    -- Save and reset lua_ls config for isolation
    saved_ls_config = vim.lsp.config.lua_ls
    vim.lsp.config("lua_ls", {})
  end)

  after_each(function()
    lsp._cached_library_paths = nil
    pcall(vim.api.nvim_del_augroup_by_name, "love2d_lsp")
    -- Restore lua_ls config
    if saved_ls_config then
      vim.lsp.config("lua_ls", saved_ls_config)
    end
  end)

  describe("_build_settings()", function()
    it("returns LuaJIT runtime", function()
      local settings = lsp._build_settings({})
      assert.are.equal("LuaJIT", settings.Lua.runtime.version)
    end)

    it("disables duplicate-set-field diagnostic", function()
      local settings = lsp._build_settings({})
      assert.is_truthy(vim.tbl_contains(settings.Lua.diagnostics.disable, "duplicate-set-field"))
    end)

    it("disables checkThirdParty", function()
      local settings = lsp._build_settings({})
      assert.is_false(settings.Lua.workspace.checkThirdParty)
    end)

    it("includes provided library paths", function()
      local settings = lsp._build_settings({ "/path/to/lib" })
      assert.are.same({ "/path/to/lib" }, settings.Lua.workspace.library)
    end)

    it("returns empty library for empty table", function()
      local settings = lsp._build_settings({})
      assert.are.same({}, settings.Lua.workspace.library)
    end)
  end)

  describe("_get_existing_library()", function()
    it("returns empty table when no lua_ls config", function()
      -- Reset to empty config (isolated from other tests)
      vim.lsp.config("lua_ls", { settings = { Lua = { workspace = { library = {} } } } })
      local lib = lsp._get_existing_library()
      assert.are.same({}, lib)
    end)

    it("returns existing library from lua_ls config", function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = {
              library = { "/existing/path" },
            },
          },
        },
      })
      local lib = lsp._get_existing_library()
      assert.are.same({ "/existing/path" }, lib)
    end)
  end)

  describe("_enable()", function()
    it("merges love paths into lua_ls config", function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = {
              library = { "/user/path" },
            },
          },
        },
      })

      local orig = stub_resolve(function()
        return { "/love/path1", "/love/path2" }
      end)

      lsp._enable()

      local lib = lsp._get_existing_library()
      assert.are.equal(3, #lib)
      assert.are.equal("/user/path", lib[1])
      assert.are.equal("/love/path1", lib[2])
      assert.are.equal("/love/path2", lib[3])

      restore_resolve(orig)
    end)

    it("caches resolved paths", function()
      local orig = stub_resolve(function()
        return { "/cached/path" }
      end)

      lsp._enable()
      assert.are.same({ "/cached/path" }, lsp._cached_library_paths)

      restore_resolve(orig)
    end)

    it("no-ops when no love paths found", function()
      local orig = stub_resolve(function()
        return {}
      end)

      lsp._enable()
      assert.is_nil(lsp._cached_library_paths)

      restore_resolve(orig)
    end)
  end)

  describe("_disable()", function()
    it("strips love paths from config", function()
      lsp._cached_library_paths = { "/love/path1", "/love/path2" }
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = {
              library = { "/user/path", "/love/path1", "/love/path2" },
            },
          },
        },
      })

      lsp._disable()

      local lib = lsp._get_existing_library()
      assert.are.same({ "/user/path" }, lib)
      assert.is_nil(lsp._cached_library_paths)
    end)

    it("no-ops when no cached paths", function()
      lsp._cached_library_paths = nil
      assert.has_no.errors(function()
        lsp._disable()
      end)
    end)
  end)

  describe("setup()", function()
    before_each(function()
      -- Reload module so the module-level augroup is recreated
      package.loaded["love2d.lsp"] = nil
      lsp = require("love2d.lsp")
    end)

    after_each(function()
      pcall(vim.api.nvim_del_augroup_by_name, "love2d_lsp")
    end)

    it("creates User autocmds for EnterLove2DProject", function()
      lsp.setup()
      local cmds = vim.api.nvim_get_autocmds({
        group = "love2d_lsp",
        event = "User",
        pattern = "EnterLove2DProject",
      })
      assert.are.equal(1, #cmds)
    end)

    it("creates User autocmds for LeaveLove2DProject", function()
      lsp.setup()
      local cmds = vim.api.nvim_get_autocmds({
        group = "love2d_lsp",
        event = "User",
        pattern = "LeaveLove2DProject",
      })
      assert.are.equal(1, #cmds)
    end)
  end)
end)
