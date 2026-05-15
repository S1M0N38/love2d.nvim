---Output panel for love2d.nvim.
---Floating scratch buffer that displays LÖVE process output (stdout + stderr).
---Errors on stderr are also pushed to vim.diagnostic for inline display.
---
---States: hidden → unfocused → focused → (cycle via :Love output)
---Auto-open on first output is always unfocused (cursor stays in code).
---
local output = {}

output.buf = nil

output.win = nil

---Diagnostic namespace for LÖVE runtime errors (separate from lua_ls).
local ns = vim.api.nvim_create_namespace("love2d_runtime")

---Current project root (set by output.start, used for file resolution).
local project_root = nil

---Whether auto-open is enabled (false when config.output = false).
local auto_open = true

---Whether user manually closed the window (suppresses auto-open until next run or explicit open).
local user_closed = false

---User-provided window config (merged with defaults).
local win_opts = nil

---Default floating window configuration.
---@return table
local function default_win_config()
  return {
    relative = "editor",
    anchor = "SE",
    width = math.floor(vim.o.columns * 0.6),
    height = math.floor(vim.o.lines * 0.25),
    row = vim.o.lines - 2,
    col = vim.o.columns,
    border = "rounded",
    title = " LÖVE Output ",
    title_pos = "center",
    style = "minimal",
    zindex = 45,
  }
end

---Keys that only apply to split windows (not floating).
local split_keys = { vertical = true, split = true }

---Keys that only apply to floating windows (not splits).
local float_keys = {
  relative = true,
  anchor = true,
  row = true,
  col = true,
  border = true,
  title = true,
  title_pos = true,
  bufpos = true,
  zindex = true,
}

---Merge user overrides with default window config.
---If the user provides split-mode keys (`vertical`, `split`), float-only keys
---are stripped so nvim_open_win() creates a proper split instead of a float.
---@param user_opts table? User-provided config (or nil for defaults).
---@return table
local function resolve_win_config(user_opts)
  local opts = user_opts or {}
  local is_split = vim.iter(opts):any(function(k, v)
    return split_keys[k] and v ~= nil
  end)
  if is_split then
    local stripped = {}
    for k, v in pairs(opts) do
      if not float_keys[k] then
        stripped[k] = v
      end
    end
    return stripped
  end
  return vim.tbl_deep_extend("force", default_win_config(), opts)
end

--------------------------------------------------------------------------------
-- Buffer management
--------------------------------------------------------------------------------

---Ensure the output buffer exists. Creates it if needed.
local function ensure_buf()
  if output.buf and vim.api.nvim_buf_is_valid(output.buf) then
    return
  end
  output.buf = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
  vim.bo[output.buf].buftype = "nofile"
  vim.bo[output.buf].bufhidden = "hide"
  vim.bo[output.buf].swapfile = false
  vim.bo[output.buf].filetype = "love2d_output"

  -- Buffer-local keymaps
  vim.keymap.set("n", "q", function()
    output.close()
  end, { buffer = output.buf, nowait = true, desc = "Close LÖVE output" })

  vim.keymap.set("n", "<CR>", function()
    output._goto_file_line()
  end, { buffer = output.buf, nowait = true, desc = "Jump to file:line under cursor" })
end

--------------------------------------------------------------------------------
-- Window management
--------------------------------------------------------------------------------

---Open the floating window. If already open, no-op.
---@param focus boolean Whether to move cursor into the window.
local function open_win(focus)
  if output.win and vim.api.nvim_win_is_valid(output.win) then
    if focus then
      vim.api.nvim_set_current_win(output.win)
    end
    return
  end
  ensure_buf()
  user_closed = false
  local config = resolve_win_config(win_opts)
  output.win = vim.api.nvim_open_win(output.buf, focus, config)
end

---Close the window (does NOT wipe the buffer).
local function close_win()
  if output.win and vim.api.nvim_win_is_valid(output.win) then
    vim.api.nvim_win_close(output.win, true)
  end
  output.win = nil
  user_closed = true
end

---Check if the user is scrolled to the bottom of the output window.
---@return boolean
local function is_at_bottom()
  if not output.win or not vim.api.nvim_win_is_valid(output.win) then
    return true
  end
  local line_count = vim.api.nvim_buf_line_count(output.buf)
  if line_count == 0 then
    return true
  end
  local cursor = vim.api.nvim_win_get_cursor(output.win)
  local win_height = vim.api.nvim_win_get_height(output.win)
  return cursor[1] >= line_count - win_height
end

---Scroll the window to the bottom if the user hasn't scrolled up.
local function maybe_scroll()
  if not output.win or not vim.api.nvim_win_is_valid(output.win) then
    return
  end
  if not is_at_bottom() then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(output.buf)
  vim.api.nvim_win_set_cursor(output.win, { line_count, 0 })
end

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------

---Parse a stderr line into file, line number, and message.
---Expected format: `filename.lua:42: error: some message`
---@param line string
---@return string? file
---@return integer? lnum
---@return string? msg
local function parse_error(line)
  local file, lnum, msg = line:match("^(%S+):(%d+):%s+(.+)$")
  if file and lnum then
    return file, tonumber(lnum), msg
  end
end

---Find a valid Neovim buffer for the given file path relative to project root.
---@param file string Relative file path (e.g. "main.lua")
---@return integer? bufnr
local function find_buf(file)
  if not project_root then
    return
  end
  local full_path = project_root .. "/" .. file
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_path = vim.api.nvim_buf_get_name(buf)
      if buf_path == full_path then
        return buf
      end
    end
  end
end

function output.push_diagnostics(lines)
  local diagnostics = {} ---@type table<integer, vim.Diagnostic[]>
  for _, line in ipairs(lines) do
    if line ~= "" then
      local file, lnum, msg = parse_error(line)
      if file and lnum and msg then
        local bufnr = find_buf(file)
        if bufnr then
          if not diagnostics[bufnr] then
            diagnostics[bufnr] = {}
          end
          table.insert(diagnostics[bufnr], {
            lnum = lnum - 1, -- vim.diagnostic uses 0-based lines
            col = 0,
            message = msg,
            severity = vim.diagnostic.severity.ERROR,
            source = "love2d",
          })
        end
      end
    end
  end
  for bufnr, diags in pairs(diagnostics) do
    -- Append to existing diagnostics (don't clear — multiple errors per run)
    local existing = vim.diagnostic.get(bufnr, { namespace = ns })
    vim.list_extend(existing, diags)
    vim.diagnostic.set(ns, bufnr, existing)
  end
end

---Clear all LÖVE runtime diagnostics across all buffers.
function output.clear_diagnostics()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.diagnostic.reset(ns, buf)
  end
end

--------------------------------------------------------------------------------
-- Public API — state queries
--------------------------------------------------------------------------------

function output.state()
  if not output.win or not vim.api.nvim_win_is_valid(output.win) then
    return "hidden"
  end
  if vim.api.nvim_get_current_win() == output.win then
    return "focused"
  end
  return "unfocused"
end

--------------------------------------------------------------------------------
-- Public API — actions
--------------------------------------------------------------------------------

function output.open()
  open_win(false)
end

function output.close()
  close_win()
  if output.buf and vim.api.nvim_buf_is_valid(output.buf) then
    vim.api.nvim_buf_delete(output.buf, { force = true })
  end
  output.buf = nil
  output.clear_diagnostics()
end

function output.focus()
  open_win(true)
end

function output.toggle()
  local s = output.state()
  if s == "hidden" then
    open_win(true)
  elseif s == "unfocused" then
    vim.api.nvim_set_current_win(output.win)
  else -- focused
    close_win()
  end
end

function output.clear()
  if output.buf and vim.api.nvim_buf_is_valid(output.buf) then
    vim.api.nvim_buf_set_lines(output.buf, 0, -1, false, {})
  end
end

function output.append(lines)
  if not lines or #lines == 0 then
    return
  end
  -- Filter empty strings (jobstart sends trailing "")
  local filtered = vim
    .iter(lines)
    :filter(function(l)
      return l ~= ""
    end)
    :totable()
  if #filtered == 0 then
    return
  end
  ensure_buf()
  -- Neovim buffers always have at least 1 line (empty). Replace it on first write.
  local line_count = vim.api.nvim_buf_line_count(output.buf)
  local first_line = vim.api.nvim_buf_get_lines(output.buf, 0, 1, false)[1]
  local start = (line_count == 1 and first_line == "") and 0 or -1
  vim.api.nvim_buf_set_lines(output.buf, start, -1, false, filtered)
  maybe_scroll()
end

function output._goto_file_line()
  local line = vim.api.nvim_get_current_line()
  local file, lnum = line:match("^(%S+):(%d+)")
  if not file or not lnum then
    return
  end
  lnum = tonumber(lnum)
  -- Resolve relative to project root
  if project_root then
    file = project_root .. "/" .. file
  end
  -- Move cursor back to the previous window first (unfocus)
  vim.cmd("wincmd p")
  vim.cmd.edit(file)
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
end

--------------------------------------------------------------------------------
-- Public API — job integration (called by job.lua)
--------------------------------------------------------------------------------

function output.start(root, opts)
  project_root = root
  auto_open = opts ~= false
  win_opts = type(opts) == "table" and opts or nil
  user_closed = false
  output.clear()
  output.clear_diagnostics()
end

function output.stop()
  -- Intentionally a no-op.
  -- The exit message is appended by on_exit in job_opts.
end

function output.job_opts(opts)
  auto_open = opts ~= false
  win_opts = type(opts) == "table" and opts or nil

  return {
    on_stdout = function(_, data)
      output.append(data)
      if auto_open and not user_closed and output.state() == "hidden" then
        open_win(false)
      end
    end,

    on_stderr = function(_, data)
      output.append(data)
      output.push_diagnostics(data)
      if auto_open and not user_closed and output.state() == "hidden" then
        open_win(false)
      end
    end,

    on_exit = function(_, code)
      output.append({ "[Process exited with code " .. code .. "]" })
    end,
  }
end

return output
