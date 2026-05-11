---@module 'luassert'

local love2d = require("love2d")

describe("init", function()
  local notify_calls
  local original_notify

  before_each(function()
    love2d.did_setup = false
    notify_calls = {}
    original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(notify_calls, { msg = msg, level = level })
    end
    -- Reset module caches so sub-modules get fresh state
    package.loaded["love2d.config"] = nil
    package.loaded["love2d.lsp"] = nil
    package.loaded["love2d.autocmd"] = nil
    package.loaded["love2d.events"] = nil
  end)

  after_each(function()
    vim.notify = original_notify
    love2d.did_setup = false
    package.loaded["love2d.config"] = nil
    package.loaded["love2d.lsp"] = nil
    package.loaded["love2d.autocmd"] = nil
    package.loaded["love2d.events"] = nil
  end)

  describe("setup()", function()
    it("sets did_setup to true", function()
      love2d.setup({})
      assert.is_true(love2d.did_setup)
    end)

    it("warns on second call", function()
      love2d.setup({})
      -- Capture count after first setup (may include events/autocmd notifications)
      local count_after_first = #notify_calls
      love2d.setup({})
      -- Second call should add exactly one warning
      assert.are.equal(count_after_first + 1, #notify_calls)
      -- The last notification should be the "already setup" warning
      local last = notify_calls[#notify_calls]
      assert.is_truthy(last.msg:match("already setup"))
    end)

    it("does not error with nil opts", function()
      assert.has_no.errors(function()
        love2d.setup(nil)
      end)
      assert.is_true(love2d.did_setup)
    end)

    it("does not error with empty opts", function()
      assert.has_no.errors(function()
        love2d.setup({})
      end)
    end)

    it("calls config.setup with opts", function()
      love2d.setup({ path_to_love_bin = "/custom/love" })
      local config = require("love2d.config")
      assert.are.equal("/custom/love", config.options.path_to_love_bin)
    end)

    it("sets up lsp autocmds by default", function()
      pcall(vim.api.nvim_del_augroup_by_name, "love2d_lsp")
      love2d.setup({})
      local cmds = vim.api.nvim_get_autocmds({
        group = "love2d_lsp",
        event = "User",
      })
      assert.are.equal(2, #cmds)
    end)

    it("skips lsp setup when lsp = false", function()
      pcall(vim.api.nvim_del_augroup_by_name, "love2d_lsp")
      love2d.setup({ lsp = false })
      local ok = pcall(vim.api.nvim_get_autocmds, {
        group = "love2d_lsp",
      })
      assert.is_false(ok)
    end)
  end)
end)
