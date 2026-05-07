# Neovim Plugin Recipes

A catalog of essential patterns for writing Neovim plugins.

> For testing patterns, see `references/TESTS.md`.
> For type annotation patterns, see `references/TYPES.md`.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Setup & Configuration](#2-setup--configuration)
3. [Module Organization](#3-module-organization)
4. [Plugin File](#4-plugin-file)
5. [Highlight Groups](#5-highlight-groups)
6. [Autocmds](#6-autocmds)
7. [Keymaps](#7-keymaps)
8. [Health Checks](#8-health-checks)
9. [Error Handling & Notifications](#9-error-handling--notifications)
10. [Type Annotations](#10-type-annotations)
11. [Debounce](#11-debounce)
12. [State Management](#12-state-management)
13. [User Commands](#13-user-commands)
14. [Anti-Patterns](#14-anti-patterns)

---

## 1. Project Structure

```
your-plugin.nvim/
├── lua/
│   └── yourplugin/
│       ├── init.lua          # Public API (setup, exported functions)
│       ├── config.lua        # Defaults, validation, highlights, augroup
│       ├── health.lua        # :checkhealth support
│       ├── util.lua          # Shared utilities (notify, debounce, etc.)
│       └── types.lua         # @meta type definitions (optional)
├── plugin/
│   └── yourplugin.lua        # User commands
├── doc/
│   └── yourplugin.txt        # Vim help file
├── tests/
│   └── *_spec.lua            # Test files
├── stylua.toml               # Code formatting
└── README.md
```

- `init.lua` — public API, delegates to config/util
- `config.lua` — defaults, validation, highlights, augroup, namespace
- `util.lua` — shared utilities (notify, debounce, exec)
- `plugin/yourplugin.lua` — commands and mappings; does NOT eagerly `require` lua modules

---

## 2. Setup & Configuration

### init.lua

```lua
-- lua/yourplugin/init.lua
local M = {}

M.did_setup = false

---@param opts? YourPlugin.Config
function M.setup(opts)
  if M.did_setup then
    return vim.notify("yourplugin is already setup", vim.log.levels.ERROR, { title = "yourplugin" })
  end
  M.did_setup = true
  require("yourplugin.config").setup(opts)
end

--- Public API function
function M.do_thing()
  return require("yourplugin.config").some_option
end

return M
```

### config.lua

```lua
-- lua/yourplugin/config.lua
local M = {}
local Util = require("yourplugin.util")

---@class YourPlugin.Config
local defaults = {
  enabled = true,
  style = "compact", ---@type "compact"|"full"
}

local config = vim.deepcopy(defaults)

-- Access config values directly: Config.style, Config.enabled
setmetatable(M, {
  __index = function(_, key)
    return config[key]
  end,
})

-- Created at module load — always available
M.augroup = vim.api.nvim_create_augroup("yourplugin", { clear = true })
M.ns = vim.api.nvim_create_namespace("yourplugin")

---@param opts? YourPlugin.Config
function M.setup(opts)
  config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})
  M.set_hl()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = M.augroup,
    callback = M.set_hl,
  })
  -- Validate config
  if config.style ~= "compact" and config.style ~= "full" then
    Util.error(("Invalid style '%s'. Expected 'compact' or 'full'"):format(config.style))
  end
end

function M.set_hl()
  -- See §5 Highlight Groups
end

return M
```

**Key rules**:
- Always `vim.deepcopy(defaults)` before merging — never mutate the defaults table
- Validate config and report errors via `Util.error` (not `error()`)
- Create augroup and namespace at module load, not inside `setup()`

---

## 3. Module Organization

A single focused plugin needs only a few modules:

```
lua/yourplugin/
├── init.lua       # Public API
├── config.lua     # Config, highlights, augroup
├── health.lua     # :checkhealth
└── util.lua       # Shared helpers
```

### util.lua

```lua
-- lua/yourplugin/util.lua
local M = {}

function M.notify(msg, level)
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = "YourPlugin" })
  end)
end

function M.info(msg)  M.notify(msg, vim.log.levels.INFO)  end
function M.warn(msg)  M.notify(msg, vim.log.levels.WARN)  end
function M.error(msg) M.notify(msg, vim.log.levels.ERROR) end

return M
```

### Adding a feature sub-module

If your plugin grows a distinct feature, add a directory:

```
lua/yourplugin/
└── picker/
    └── init.lua
```

Load it on demand from `init.lua`:

```lua
function M.picker(opts)
  return require("yourplugin.picker").open(opts)
end
```

---

## 4. Plugin File

The `plugin/` file loads at startup. Keep it minimal.

```lua
-- plugin/yourplugin.lua
vim.api.nvim_create_user_command("YourPlugin", function(args)
  require("yourplugin").command(args)
end, {
  nargs = "?",
  desc = "YourPlugin",
})
```

**Key rule**: The `require("yourplugin")` is inside the callback — the main
module is only loaded when the user actually invokes the command.

---

## 5. Highlight Groups

### Define Highlights with Link Map

```lua
-- in config.lua
function M.set_hl()
  local links = {
    Title = "FloatTitle",
    Border = "FloatBorder",
    Normal = "NormalFloat",
    Error = "DiagnosticError",
    Sign = "Special",
  }
  for name, target in pairs(links) do
    vim.api.nvim_set_hl(0, "YourPlugin" .. name, { link = target, default = true })
  end
end
```

**Rules**:
1. Prefix all groups with `YourPlugin`
2. Always `link` to built-in groups — never hardcode colors
3. Always set `default = true` — user colorschemes take precedence
4. Re-apply on `ColorScheme` autocmd (already done in `setup()`)

---

## 6. Autocmds

### Always Use a Dedicated Augroup

```lua
-- Global
local augroup = vim.api.nvim_create_augroup("yourplugin", { clear = true })

-- Per-buffer
local buf_augroup = vim.api.nvim_create_augroup("yourplugin_buf_" .. buf, { clear = true })
```

### Buffer-Local Autocmds

```lua
vim.api.nvim_create_autocmd({ "CursorMoved" }, {
  group = augroup,
  buffer = buf,
  callback = function(ev)
    -- handle event for this buffer only
  end,
})
```

### Cleanup with pcall

Always protect cleanup — the resource may already be gone:

```lua
pcall(vim.api.nvim_del_augroup_by_id, augroup)
pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
pcall(vim.api.nvim_buf_delete, buf, { force = true })
```

---

## 7. Keymaps

### Option A: `<Plug>` Mappings for Classic Vim-Style Remappability

Best for plugins whose actions users may want to remap to different keys.

```lua
-- In your plugin:
vim.keymap.set("n", "<Plug>(YourPluginAction)", function()
  require("yourplugin").do_action()
end)

-- User maps in their config:
vim.keymap.set("n", "<leader>a", "<Plug>(YourPluginAction)")
```

Works even if plugin is not installed. No custom DSL needed.

### Option B: Keymap Configuration in `setup()`

Best for plugins with many actions or complex multi-key sequences. Also common in
the ecosystem (telescope, blink.cmp, snacks.nvim all use this approach).

```lua
---@class YourPlugin.Keys: vim.api.keyset.set_keymap
---@field [1] string LHS
---@field [2] string|fun() RHS

---@class YourPlugin.Config
---@field keys? table<string, YourPlugin.Keys>

-- User config:
require("yourplugin").setup({
  keys = {
    action = { "n", "<leader>a", desc = "Do action" },
  },
})
```

Allow users to disable defaults by setting to `""`:

```lua
local function map(mode, lhs, rhs, opts)
  if lhs == "" then return end
  opts = vim.tbl_deep_extend("force", { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end
```

### Buffer-Local Keymaps for Plugin Windows

Regardless of which option you choose for user-facing actions, always use
buffer-local keymaps for plugin UI windows:

```lua
vim.keymap.set("n", "q", function()
  M:close()
end, { buffer = buf, nowait = true, desc = "Close window" })
```

---

## 8. Health Checks

```lua
-- lua/yourplugin/health.lua
local M = {}

function M.check()
  vim.health.start("yourplugin")

  if require("yourplugin").did_setup then
    vim.health.ok("setup() was called")
  else
    vim.health.error("setup() was not called")
  end

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is required")
  end
end

return M
```

- File must be `lua/yourplugin/health.lua`
- Must export `M.check()` (called by `:checkhealth yourplugin`)

---

## 9. Error Handling & Notifications

### Use `vim.notify`, never `print()`

Always `vim.schedule` notifications to avoid issues in fast event loops:

```lua
function M.notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = "YourPlugin" })
  end)
end
```

### pcall for API Calls That Might Fail

```lua
pcall(vim.api.nvim_buf_delete, buf, { force = true })

local ok, mod = pcall(require, "optional-plugin")
if ok then mod.do_thing() end

local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
```

---

## 10. Type Annotations

### Config Class

```lua
---@class YourPlugin.Config
---@field enabled? boolean Whether the plugin is enabled (default: true)
---@field style? "compact"|"full" Display style (default: "compact")
```

Use `?` for optional fields. Users don't need to set every option.

### Function Annotations

```lua
---@param opts? YourPlugin.Config
function M.setup(opts) end

---@return string
function M.do_thing() end
```

### Separate Types File

For global type definitions:

```lua
-- lua/yourplugin/types.lua
---@meta

---@class YourPlugin.PublicApi
---@field setup fun(opts?: YourPlugin.Config)
---@field do_thing fun(): string
```

For the full LuaCATS reference, see `references/TYPES.md`.

---

## 11. Debounce

Fire only after `ms` milliseconds of inactivity. Useful for `CursorMoved`,
`TextChanged`, and other high-frequency events:

```lua
-- in util.lua
function M.debounce(fn, ms)
  local timer = assert(vim.uv.new_timer())
  local function debounced(...)
    local args = { ... }
    timer:stop()
    timer:start(ms or 20, 0, vim.schedule_wrap(function()
      local ok, err = pcall(fn, unpack(args))
      if not ok then
        M.error("debounced function failed: " .. tostring(err))
      end
    end))
  end
  function debounced.cancel()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  return debounced
end
```

Usage:

```lua
local update = Util.debounce(function(ev)
  M.update(ev.buf)
end, 50)

vim.api.nvim_create_autocmd({ "CursorMoved" }, {
  group = augroup,
  buffer = buf,
  callback = update,
})

-- Clean up when done:
update.cancel()
```

---

## 12. State Management

### Per-Buffer Cache

Track state per buffer, clean up on detach:

```lua
local cache = {} ---@type table<integer, table>
local ns = vim.api.nvim_create_namespace("yourplugin")

function M.enable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if cache[buf] then return end -- already enabled

  local augroup = vim.api.nvim_create_augroup("yourplugin_buf_" .. buf, { clear = true })
  cache[buf] = { augroup = augroup }

  -- Auto-cleanup on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    buffer = buf,
    callback = function()
      M.disable(buf)
    end,
  })
end

function M.disable(buf)
  buf = buf or 0
  local state = cache[buf]
  if not state then return end
  cache[buf] = nil
  pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
  pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
end
```

### Disable Check

Allow users to disable per-buffer or globally:

```lua
function M.is_disabled(buf)
  return vim.g.yourplugin_disable == true
    or vim.b[buf or 0].yourplugin_disable == true
end
```

---

## 13. User Commands

Gather subcommands under one root command:

```lua
-- plugin/yourplugin.lua
local subcommands = {
  enable = {
    impl = function(args)
      require("yourplugin").enable()
    end,
    complete = function()
      return { "true", "false" }
    end,
  },
  status = {
    impl = function(args)
      require("yourplugin").status()
    end,
  },
}

vim.api.nvim_create_user_command("YourPlugin", function(opts)
  local sub = subcommands[opts.fargs[1]]
  if not sub then
    return vim.notify("Unknown subcommand: " .. tostring(opts.fargs[1]), vim.log.levels.ERROR)
  end
  sub.impl(vim.list_slice(opts.fargs, 2))
end, {
  nargs = "+",
  desc = "YourPlugin",
  complete = function(arg_lead, cmdline, _)
    -- Subcommand argument completion
    local subcmd, subcmd_arg = cmdline:match("^['<,'>]*YourPlugin[!]*%s(%S+)%s(.*)$")
    if subcmd and subcmd_arg and subcommands[subcmd] and subcommands[subcmd].complete then
      return subcommands[subcmd].complete(subcmd_arg)
    end
    -- Subcommand name completion
    if cmdline:match("^['<,'>]*YourPlugin[!]*%s+%w*$") then
      return vim.iter(vim.tbl_keys(subcommands))
        :filter(function(k) return k:find(arg_lead) ~= nil end)
        :totable()
    end
  end,
})
```

---

## 14. Anti-Patterns

### ❌ Hard-code highlight colors

```lua
-- ❌ Breaks with theme changes
vim.api.nvim_set_hl(0, "MyHighlight", { fg = "#ff0000" })

-- ✅ Link to built-in groups
vim.api.nvim_set_hl(0, "MyHighlight", { link = "Error", default = true })
```

### ❌ Eagerly require in plugin/ files

```lua
-- ❌ Loads entire plugin at startup
local plugin = require("yourplugin")
vim.api.nvim_create_user_command("Foo", function()
  plugin.do_thing()
end, {})

-- ✅ Lazy require in callback
vim.api.nvim_create_user_command("Foo", function()
  require("yourplugin").do_thing()
end, {})
```

### ❌ Mutate defaults table

```lua
-- ❌
config = vim.tbl_deep_extend("force", defaults, opts or {})
-- ✅
config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), opts or {})
```

### ❌ Use version checks over feature detection

```lua
-- ❌ In runtime code — fragile, breaks on nightly builds
if vim.fn.has("nvim-0.10") == 1 then ... end
-- ✅ Use feature detection
if vim.diagnostic.enable then ... end
```

> **Note**: Version checks are appropriate in health checks (informing users about
> minimum requirements) and top-level guard clauses. Feature detection is preferred
> in runtime code where the behavior depends on a specific API.

### ❌ Create a custom keymap DSL in setup()

```lua
-- ❌ Forces users to learn your DSL
require("yourplugin").setup({ mappings = { ["<leader>f"] = "find" } })

-- ✅ Use <Plug> mappings — one line in user config
vim.keymap.set("n", "<leader>f", "<Plug>(YourPluginFind)")
```

### ❌ Use synchronous `vim.fn.system()` for external commands

```lua
-- ❌ Blocks Neovim
vim.fn.system({ "git", "status" })
-- ✅ Use async vim.system()
vim.system({ "git", "status" }, function(result)
  -- handle result in callback
end)
```

### ❌ Skip buffer validity checks

```lua
-- ❌ Buffer may have been deleted by the time you operate on it
vim.api.nvim_buf_set_lines(buf, ...)
-- ✅ Always check validity first
if vim.api.nvim_buf_is_valid(buf) then
  vim.api.nvim_buf_set_lines(buf, ...)
end
```

### ❌ Use `error()` for user-facing errors

```lua
-- ❌ Crashes the call chain
error("Invalid config")
-- ✅ Soft notification, plugin degrades gracefully
Util.error("Invalid config")
```
