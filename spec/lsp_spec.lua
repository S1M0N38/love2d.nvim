require("love2d")
local config = require("love2d.config")

-- Mock vim.notify to suppress output during tests
---@diagnostic disable-next-line: duplicate-set-field
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

describe("LSP functionality", function()
  local function cleanup_lsp()
    -- Stop all lua_ls clients
    local clients = vim.lsp.get_clients({ name = "lua_ls" })
    for _, client in ipairs(clients) do
      vim.lsp.stop_client(client.id, true)
    end
    vim.wait(1000) -- Wait for cleanup
  end

  local function wait_for_lsp_attach()
    local max_wait = 5000 -- 5 seconds
    local waited = 0
    while waited < max_wait do
      local clients = vim.lsp.get_clients({ name = "lua_ls" })
      if #clients > 0 and clients[1].initialized then
        return clients[1]
      end
      vim.wait(100)
      waited = waited + 100
    end
    return nil
  end

  before_each(function()
    cleanup_lsp()
  end)

  after_each(function()
    cleanup_lsp()
  end)

  describe("LSP configuration", function()
    it("configures lua_ls with Love2D libraries", function()
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. vim.fn.getcwd() .. "/tests/game")

      -- Configure lua_ls server command if not already configured
      if not vim.lsp.config.lua_ls or not vim.lsp.config.lua_ls.cmd then
        vim.lsp.config("lua_ls", {
          cmd = { "lua-language-server" },
        })
      end

      config.setup(opts)
      local client = wait_for_lsp_attach()

      vim.cmd("cd " .. old_cwd)

      if client then
        assert.are.equal("lua_ls", client.name)
        ---@diagnostic disable-next-line: undefined-field
        local libraries = client.config.settings.Lua.workspace.library
        assert.is_not_nil(libraries)

        local has_love2d = false
        local has_luasocket = false
        for _, lib in ipairs(libraries) do
          if lib:match("love2d") then
            has_love2d = true
          end
          if lib:match("luasocket") then
            has_luasocket = true
          end
        end

        assert.truthy(has_love2d)
        assert.truthy(has_luasocket)
        ---@diagnostic disable-next-line: undefined-field
        assert.are.equal("LuaJIT", client.config.settings.Lua.runtime.version)
        ---@diagnostic disable-next-line: undefined-field
        assert.are.equal(false, client.config.settings.Lua.workspace.checkThirdParty)
      end
    end)

    it("does not show love as undefined global", function()
      local old_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. vim.fn.getcwd() .. "/tests/game")

      -- Configure lua_ls server command if not already configured
      if not vim.lsp.config.lua_ls or not vim.lsp.config.lua_ls.cmd then
        vim.lsp.config("lua_ls", {
          cmd = { "lua-language-server" },
        })
      end

      config.setup(opts)
      local client = wait_for_lsp_attach()

      if client then
        -- Open the main.lua file to trigger diagnostics
        vim.cmd("edit main.lua")
        vim.wait(3000) -- Wait for diagnostics to process

        local diagnostics = vim.diagnostic.get(0)

        -- Check that there are no "undefined global 'love'" diagnostics
        local has_love_undefined = false
        for _, diagnostic in ipairs(diagnostics) do
          if diagnostic.message:match("undefined global.*love") then
            has_love_undefined = true
            break
          end
        end

        assert.falsy(has_love_undefined)
      end

      vim.cmd("cd " .. old_cwd)
    end)
  end)
end)
