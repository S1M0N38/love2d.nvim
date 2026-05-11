---Health check module for love2d.nvim.
---Provides comprehensive diagnostics via `:checkhealth love2d`.
---
---Reports on:
---   1. Plugin setup status
---   2. Neovim version compatibility
---   3. LÖVE binary availability and version
---   4. lua-language-server binary and configuration
---   5. Type-definition library submodules (LÖVE + LuaSocket)
---   6. Treesitter parsers (lua + glsl)
---   7. GLSL injection query for shader syntax highlighting
---   8. Plugin runtime state (project detection, job status, output panel)
local health = {}

---Minimum supported Neovim version string.
local MIN_NVIM_VERSION = "0.12.2"

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

---Run a shell command synchronously and return trimmed stdout.
---@param cmd string Shell command.
---@return string? output Trimmed stdout, or nil on failure.
local function shell_output(cmd)
  local ok, out = pcall(vim.fn.system, cmd)
  if ok and vim.v.shell_error == 0 and out ~= "" then
    return vim.trim(out)
  end
end

---Format a version table as "major.minor.patch".
---@param v table|vim.Version { major, minor, patch }, { 1, 2, 3 }, or vim.Version.
---@return string
local function version_str(v)
  if type(v) == "table" then
    if v.major then
      return string.format("%d.%d.%d", v.major, v.minor or 0, v.patch or 0)
    end
    -- Array-style table: { major, minor, patch }
    return string.format("%d.%d.%d", v[1] or 0, v[2] or 0, v[3] or 0)
  end
  return tostring(v)
end

---Check if current Neovim version meets the minimum requirement.
---@return boolean ok
---@return string current Version string.
---@return string minimum Minimum version string.
local function check_nvim_version()
  local current = vim.version()
  local minimum = vim.version.parse(MIN_NVIM_VERSION) --[[@as vim.Version]]
  local ok = vim.version.ge(current, minimum)
  return ok, tostring(current), tostring(minimum)
end

---Resolve the LÖVE binary path from config or default.
---@return string bin Configured or default binary name/path.
local function get_love_bin()
  local ok, config = pcall(require, "love2d.config")
  if ok and config.options and config.options.path_to_love_bin then
    return config.options.path_to_love_bin
  end
  return "love"
end

---Try to detect the LÖVE version by running `love --version`.
---@param bin string Binary path/name.
---@return string? version Version string (e.g. "11.5"), or nil.
local function get_love_version(bin)
  -- Try `love --version` first (standard across platforms)
  local out = shell_output(vim.fn.shellescape(bin) .. " --version 2>&1")
  if out then
    -- Typical output: "LOVE 11.5 (Mysterious Mysteries)"
    local ver = out:match("(%d+%.%d+[%.%d]*)")
    if ver then
      return ver
    end
    -- Return the whole line if no version pattern found
    return out
  end
end

---Check if the treesitter parser for a language is installed.
---@param lang string Language name (e.g. "lua", "glsl").
---@return boolean installed
local function has_ts_parser(lang)
  local ok = pcall(vim.treesitter.language.inspect, lang)
  return ok
end

---Check if the GLSL injection query file exists on runtimepath.
---@return boolean found
---@return string? path Absolute path to the query file, if found.
local function find_glsl_injection()
  local paths = vim.api.nvim_get_runtime_file("queries/lua/injections.scm", true)
  for _, path in ipairs(paths) do
    -- Check that it's from our plugin
    if path:match("love2d") then
      return true, path
    end
  end
  return false, nil
end

---Get the current plugin runtime state as a summary table.
---@return table state
local function get_runtime_state()
  local state = {
    in_project = false,
    project_path = nil,
    main_lua = nil,
    job_running = false,
    job_watching = false,
    output_state = "hidden",
  }

  local ok, job = pcall(require, "love2d.job")
  if ok and job.state then
    state.in_project = job.state.path_to_love2d_project ~= nil
    state.project_path = job.state.path_to_love2d_project
    state.main_lua = job.state.path_to_main_lua
    state.job_running = job.state.id ~= nil
    state.job_watching = job.state.watching == true
  end

  local ok2, output = pcall(require, "love2d.output")
  if ok2 and output.state then
    state.output_state = output.state()
  end

  return state
end

---------------------------------------------------------------------------
-- Health check sections
---------------------------------------------------------------------------

---Section 1: Plugin setup status.
local function check_setup()
  vim.health.start("love2d.nvim setup")

  local love2d = require("love2d")
  if love2d.did_setup then
    vim.health.ok("setup() has been called")
  else
    vim.health.error(
      "setup() has not been called",
      "Add `require('love2d').setup()` to your init.lua or a plugin spec."
    )
  end
end

---Section 2: Neovim version compatibility.
local function check_nvim()
  vim.health.start("Neovim version")

  local ok, current, minimum = check_nvim_version()
  if ok then
    vim.health.ok("Neovim " .. current .. " >= " .. minimum)
  else
    vim.health.error(
      "Neovim " .. current .. " is below the minimum required version " .. minimum,
      "Upgrade Neovim to " .. minimum .. " or later."
    )
  end
end

---Section 3: LÖVE binary availability and version.
local function check_love_binary()
  vim.health.start("LÖVE binary")

  local bin = get_love_bin()
  local is_default = bin == "love"

  if vim.fn.executable(bin) == 1 then
    -- (label is unused; the binary path is shown in the ok message)
    vim.health.ok("LÖVE binary found: `" .. bin .. "`")

    -- Try to detect the version
    local version = get_love_version(bin)
    if version then
      vim.health.ok("LÖVE version: " .. version)
    else
      vim.health.info("Could not detect LÖVE version")
    end
  else
    local advice = is_default and "Install LÖVE from https://love2d.org/ or set `path_to_love_bin` in setup()."
      or "Check that `" .. bin .. "` exists and is executable, or update `path_to_love_bin` in setup()."
    vim.health.warn("LÖVE binary not found: `" .. bin .. "`", advice)
  end
end

---Section 4: lua-language-server binary and configuration.
local function check_lua_ls()
  vim.health.start("lua-language-server")

  -- Binary check
  if vim.fn.executable("lua-language-server") == 1 then
    vim.health.ok("`lua-language-server` is installed")

    -- Try to detect version
    local out = shell_output("lua-language-server --version 2>&1")
    if out then
      -- Typical output: "lua-language-server 3.13.5" or similar
      vim.health.info("Version: " .. out)
    end
  else
    vim.health.warn(
      "`lua-language-server` is not installed",
      "Install lua-language-server for LSP support (completions, diagnostics, hover, etc.)."
    )
    return -- No point checking config if binary is missing
  end

  -- Check if lua_ls is configured via vim.lsp.config
  local ok, cfg = pcall(function()
    return vim.lsp.config.lua_ls
  end)
  if ok and cfg then
    vim.health.ok("lua_ls is configured via `vim.lsp.config`")
  else
    vim.health.info("lua_ls is not yet configured (it will be auto-configured when entering a LÖVE project)")
  end

  -- Check if lua_ls is enabled
  if vim.lsp.is_enabled("lua_ls") then
    vim.health.ok("lua_ls is enabled for auto-activation")
  else
    vim.health.info("lua_ls is not currently enabled — it will be enabled automatically on project enter")
  end

  -- Check if any lua_ls clients are active
  local clients = vim.lsp.get_clients({ name = "lua_ls" })
  if #clients > 0 then
    vim.health.ok("lua_ls is running (" .. #clients .. " client(s) active)")
  else
    vim.health.info("No lua_ls clients are currently running")
  end
end

---Section 5: Type-definition library submodules.
local function check_type_definitions()
  vim.health.start("Type definitions")

  local ok, lsp = pcall(require, "love2d.lsp")
  if not ok then
    vim.health.error("Could not load `love2d.lsp` module")
    return
  end

  local paths = lsp._resolve_library_paths()
  local love_found = false
  local luasocket_found = false

  for _, path in ipairs(paths) do
    if path:match("libraries/love2d/library") then
      love_found = true
      vim.health.ok("LÖVE type definitions: `" .. path .. "`")
    elseif path:match("libraries/luasocket/library") then
      luasocket_found = true
      vim.health.ok("LuaSocket type definitions: `" .. path .. "`")
    end
  end

  if not love_found then
    vim.health.warn(
      "LÖVE type definitions not found",
      "Run `git submodule update --init --recursive` in the plugin directory."
    )
  end

  if not luasocket_found then
    vim.health.warn(
      "LuaSocket type definitions not found",
      "Run `git submodule update --init --recursive` in the plugin directory."
    )
  end
end

---Section 6: Treesitter parsers.
local function check_treesitter()
  vim.health.start("Treesitter parsers")

  -- Lua parser (essential)
  if has_ts_parser("lua") then
    vim.health.ok("Treesitter `lua` parser is installed")
  else
    vim.health.warn(
      "Treesitter `lua` parser is not installed",
      "Run `:TSInstall lua` or `vim.treesitter.install('lua')` for syntax highlighting and textobjects."
    )
  end

  -- GLSL parser (optional but recommended for shader support)
  if has_ts_parser("glsl") then
    vim.health.ok("Treesitter `glsl` parser is installed (shader syntax highlighting)")
  else
    vim.health.info(
      "Treesitter `glsl` parser is not installed — shader code inside `newShader()` calls will not be highlighted"
    )
    vim.health.info("Install with `:TSInstall glsl` or `vim.treesitter.install('glsl')` for full shader support.")
  end
end

---Section 7: GLSL injection query.
local function check_glsl_injection()
  vim.health.start("GLSL injection")

  local found, path = find_glsl_injection()
  if found then
    vim.health.ok("GLSL injection query is installed: `" .. path .. "`")
  else
    vim.health.warn(
      "GLSL injection query not found",
      "The `after/queries/lua/injections.scm` file provides GLSL syntax highlighting inside `newShader()` calls. "
        .. "Make sure the plugin is properly installed on `runtimepath`."
    )
  end
end

---Section 8: Plugin runtime state.
local function check_runtime_state()
  vim.health.start("Runtime state")

  local state = get_runtime_state()

  if not state.in_project then
    vim.health.info("Not currently inside a LÖVE project")
    vim.health.info(
      "Open a LÖVE project directory (with `conf.lua` or `main.lua` containing LÖVE callbacks) to activate the plugin."
    )
    return
  end

  vim.health.ok("LÖVE project detected: `" .. state.project_path .. "`")

  if state.main_lua then
    vim.health.ok("Entry point: `" .. state.main_lua .. "`")
  else
    vim.health.warn(
      "No `main.lua` found in project root",
      "The project will still run, but `:Love run` uses the project directory directly."
    )
  end

  -- Job status
  if state.job_running then
    vim.health.ok("LÖVE process is running")
  else
    vim.health.info("No LÖVE process is currently running")
  end

  if state.job_watching then
    vim.health.ok("Watch mode is active (auto-restart on save)")
  end

  -- Output panel
  vim.health.info("Output panel state: " .. state.output_state)
end

---Section 9: Config validation.
---Checks for unknown keys in user-provided configuration.
local function check_config()
  vim.health.start("Configuration")

  local ok, config = pcall(require, "love2d.config")
  if not ok or not config.options then
    vim.health.info("No configuration loaded")
    return
  end

  local valid_keys = {
    path_to_love_bin = true,
    output = true,
    lsp = true,
  }

  local unknown = {}
  for key, _ in pairs(config.options) do
    if not valid_keys[key] then
      table.insert(unknown, key)
    end
  end

  if #unknown == 0 then
    vim.health.ok("No unknown configuration options")
  else
    table.sort(unknown)
    local list = table.concat(unknown, ", ")
    vim.health.warn(
      "Unknown configuration option(s): " .. list,
      "Check :help love2d-setup for valid options. Valid keys: " .. table.concat(vim.tbl_keys(valid_keys), ", ")
    )
  end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

---Run all health checks for `:checkhealth love2d`.
function health.check()
  check_setup()
  check_nvim()
  check_love_binary()
  check_lua_ls()
  check_type_definitions()
  check_treesitter()
  check_glsl_injection()
  check_runtime_state()
  check_config()
end

return health
