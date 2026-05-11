---@module 'luassert'

local output = require("love2d.output")

describe("output", function()
  before_each(function()
    -- Close any existing output state
    output.close()
  end)

  after_each(function()
    output.close()
  end)

  describe("state()", function()
    it("returns 'hidden' when no window", function()
      assert.are.equal("hidden", output.state())
    end)
  end)

  describe("append()", function()
    it("appends lines to buffer", function()
      output.append({ "line 1", "line 2" })
      assert.is_not_nil(output.buf)
      assert.is_truthy(vim.api.nvim_buf_is_valid(output.buf))
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      assert.are.equal("line 1", lines[1])
      assert.are.equal("line 2", lines[2])
    end)

    it("filters empty strings", function()
      output.append({ "hello", "", "world", "" })
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      assert.are.equal(2, #lines)
      assert.are.equal("hello", lines[1])
      assert.are.equal("world", lines[2])
    end)

    it("no-ops on empty input", function()
      output.append({})
      assert.is_nil(output.buf)
    end)

    it("no-ops on all-empty strings", function()
      output.append({ "", "", "" })
      assert.is_nil(output.buf)
    end)

    it("appends after initial write (does not duplicate first line)", function()
      output.append({ "first" })
      output.append({ "second" })
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      assert.are.equal(2, #lines)
      assert.are.equal("first", lines[1])
      assert.are.equal("second", lines[2])
    end)
  end)

  describe("open() / close() / toggle()", function()
    it("open() creates unfocused window", function()
      output.open()
      assert.are.equal("unfocused", output.state())
      assert.is_not_nil(output.win)
      assert.is_truthy(vim.api.nvim_win_is_valid(output.win))
    end)

    it("close() hides window and wipes buffer", function()
      output.open()
      output.close()
      assert.are.equal("hidden", output.state())
      assert.is_nil(output.win)
      assert.is_nil(output.buf)
    end)

    it("toggle() opens when hidden", function()
      output.toggle()
      assert.are.equal("focused", output.state())
    end)

    it("toggle() focuses when unfocused", function()
      output.open() -- unfocused
      assert.are.equal("unfocused", output.state())
      output.toggle()
      assert.are.equal("focused", output.state())
    end)

    it("toggle() hides when focused", function()
      output.toggle() -- opens + focuses
      assert.are.equal("focused", output.state())
      output.toggle() -- closes
      assert.are.equal("hidden", output.state())
    end)

    it("open() is no-op when already open", function()
      output.open()
      local first_win = output.win
      output.open()
      assert.are.equal(first_win, output.win)
    end)
  end)

  describe("clear()", function()
    it("wipes buffer content", function()
      output.append({ "some text" })
      output.clear()
      assert.is_not_nil(output.buf)
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      -- Neovim buffers always have >= 1 line; after clear it's just an empty line
      assert.are.equal(1, #lines)
      assert.are.equal("", lines[1])
    end)

    it("no-ops when no buffer", function()
      assert.has_no.errors(function()
        output.clear()
      end)
    end)
  end)

  describe("push_diagnostics()", function()
    it("parses error lines without error", function()
      output.start("/fake/root", nil)
      assert.has_no.errors(function()
        output.push_diagnostics({ "main.lua:10: attempt to call nil value" })
      end)
    end)

    it("ignores lines without file:line:msg pattern", function()
      output.start("/fake/root", nil)
      assert.has_no.errors(function()
        output.push_diagnostics({ "some random output" })
      end)
    end)

    it("sets diagnostics on matching buffer", function()
      -- Create a real temp file and buffer
      local tmpdir = vim.fn.resolve(vim.fn.tempname())
      vim.fn.mkdir(tmpdir, "p")
      local tmp = tmpdir .. "/main.lua"
      vim.fn.writefile({ "local x = 1" }, tmp)
      local buf = vim.fn.bufadd(tmp)
      vim.fn.bufload(buf)
      vim.bo[buf].buflisted = true
      vim.api.nvim_set_current_buf(buf)

      local ns = vim.api.nvim_create_namespace("love2d_runtime")
      output.start(tmpdir, nil)
      output.push_diagnostics({ "main.lua:5: attempt to call nil" })

      local diags = vim.diagnostic.get(buf, { namespace = ns })
      assert.are.equal(1, #diags)
      assert.are.equal(4, diags[1].lnum) -- 0-based (line 5 → lnum 4)
      assert.is_truthy(diags[1].message:match("attempt to call nil"))

      -- Cleanup
      vim.diagnostic.reset(ns, buf)
      vim.api.nvim_buf_delete(buf, { force = true })
      vim.fn.delete(tmpdir, "rf")
    end)
  end)

  describe("clear_diagnostics()", function()
    it("clears all diagnostics without error", function()
      assert.has_no.errors(function()
        output.clear_diagnostics()
      end)
    end)
  end)

  describe("start()", function()
    it("clears buffer content", function()
      output.append({ "old output" })
      output.start("/fake/root", nil)
      -- Buffer should still exist and be cleared
      assert.is_not_nil(output.buf)
      assert.is_truthy(vim.api.nvim_buf_is_valid(output.buf))
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      assert.are.equal(1, #lines)
      assert.are.equal("", lines[1])
    end)
  end)

  describe("job_opts()", function()
    it("returns table with callable callbacks", function()
      local opts = output.job_opts(nil)
      assert.is_function(opts.on_stdout)
      assert.is_function(opts.on_stderr)
      assert.is_function(opts.on_exit)
    end)

    it("on_stdout appends to buffer", function()
      local opts = output.job_opts(nil)
      opts.on_stdout(0, { "hello from stdout" })
      assert.is_not_nil(output.buf)
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      assert.are.equal("hello from stdout", lines[1])
    end)

    it("on_stderr appends to buffer and pushes diagnostics", function()
      -- Create a real temp file + buffer so push_diagnostics can match
      local tmpdir = vim.fn.resolve(vim.fn.tempname())
      vim.fn.mkdir(tmpdir, "p")
      local tmp = tmpdir .. "/main.lua"
      vim.fn.writefile({ "local x = 1" }, tmp)
      local buf = vim.fn.bufadd(tmp)
      vim.fn.bufload(buf)
      vim.bo[buf].buflisted = true
      vim.api.nvim_set_current_buf(buf)

      local ns = vim.api.nvim_create_namespace("love2d_runtime")
      output.start(tmpdir, nil)
      local opts = output.job_opts(nil)
      opts.on_stderr(0, { "main.lua:3: syntax error near 'for'" })

      -- Buffer should have the error line
      assert.is_not_nil(output.buf)
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      assert.is_truthy(lines[1]:match("syntax error"))

      -- Diagnostics should be set on the source buffer
      local diags = vim.diagnostic.get(buf, { namespace = ns })
      assert.are.equal(1, #diags)
      assert.are.equal(2, diags[1].lnum) -- 0-based (line 3 → lnum 2)
      assert.is_truthy(diags[1].message:match("syntax error"))

      -- Cleanup
      vim.diagnostic.reset(ns, buf)
      vim.api.nvim_buf_delete(buf, { force = true })
      vim.fn.delete(tmpdir, "rf")
    end)

    it("on_exit appends exit code", function()
      local opts = output.job_opts(nil)
      opts.on_exit(0, 42)
      local lines = vim.api.nvim_buf_get_lines(output.buf, 0, -1, false)
      local found = false
      for _, line in ipairs(lines) do
        if line:match("exited with code 42") then
          found = true
        end
      end
      assert.is_true(found)
    end)
  end)
end)
