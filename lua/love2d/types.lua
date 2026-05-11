---@meta _

--===========================================================================
-- love2d.nvim — Complete Type Definitions
--===========================================================================
--
-- Canonical source of truth for ALL type definitions in love2d.nvim.
-- This is a LuaLS definition file — never required at runtime, used only for
-- type checking, completion, and hover documentation.
--
-- Source files reference these types via `---@type` annotations on their
-- module tables, which connects LuaLS's resolver to the definitions here.
--
-- Sections:
--   1. Aliases
--   2. Configuration
--   3. Job State
--   4. Output Panel
--   5. Events
--   6. LSP Settings
--   7. Module APIs
--
-- Modules annotated here:
--   love2d          (init.lua)        — Public API entry point
--   love2d.config   (config.lua)      — Option merging
--   love2d.utils    (utils.lua)       — Project detection helpers
--   love2d.job      (job.lua)         — Process lifecycle
--   love2d.output   (output.lua)      — Floating output panel + diagnostics
--   love2d.events   (events.lua)      — DirChange/BufEnter project detection
--   love2d.autocmd  (autocmd.lua)     — Enter/Leave autocmd handlers
--   love2d.lsp      (lsp.lua)         — lua_ls configuration
--   love2d.health   (health.lua)      — :checkhealth support
--===========================================================================

---------------------------------------------------------------------------
-- 1. Aliases
---------------------------------------------------------------------------

---State of the output panel window.
---
---| State       | Meaning                                |
---|-------------|----------------------------------------|
---| "hidden"    | Window does not exist                  |
---| "unfocused" | Window is visible, cursor is elsewhere |
---| "focused"   | Cursor is inside the output window     |
---@alias Love2D.Output.State "hidden"|"unfocused"|"focused"

---------------------------------------------------------------------------
-- 2. Configuration
---------------------------------------------------------------------------

---User-facing configuration for love2d.nvim.
---All fields are optional — sensible defaults are applied by `config.setup()`.
---
---Example:
---```lua
---require("love2d").setup({
---  path_to_love_bin = "/usr/bin/love",
---  output = {
---    width = 80,
---    height = 20,
---    border = "single",
---  },
---})
---```
---@class Love2D.Config
---@field path_to_love_bin? string Path to the LÖVE executable. (default: `"love"`)
---@field output? false|Love2D.Output.WinConfig Output panel behavior. `false` disables auto-open (diagnostics still appear inline). A table is merged with the default floating-window config.
---@field lsp? boolean Enable automatic lua_ls configuration for LÖVE projects. (default: `true`)
--- Set to `false` to provide your own LSP config or use a different language server.

---------------------------------------------------------------------------
-- 3. Job State
---------------------------------------------------------------------------

---Tracks the currently detected LÖVE project and running process.
---Accessed as `require("love2d.job").state`.
---@class Love2D.Job.State
---@field path_to_love2d_project? string Absolute path to the detected LÖVE project root, or `nil` if not in a project.
---@field path_to_main_lua? string Absolute path to `main.lua` within the project, or `nil` if not found.
---@field id? integer Job handle from `vim.fn.jobstart`, or `nil` when no process is running.
---@field exit_code? integer Exit code from the most recent process termination. Reset to `nil` on the next `run()` / `watch()`.
---@field watching boolean Whether watch mode (auto-restart on save) is active.
---@field restarting boolean `true` while a restart is in progress — prevents `on_exit` from tearing down watch state.
---@field watch_generation integer Monotonic counter bumped on every restart/stop. Used to cancel stale `vim.defer_fn` callbacks.

---------------------------------------------------------------------------
-- 4. Output Panel
---------------------------------------------------------------------------

---Floating-window configuration for the LÖVE output panel.
---Any subset of fields can be provided via `Love2D.Config.output`;
---they are merged with the defaults by the output module.
---@class Love2D.Output.WinConfig
---@field relative? string Coordinate reference. (default: `"editor"`)
---@field anchor? string Corner anchor for positioning. (default: `"SE"`)
---@field width? integer Window width in columns. (default: `math.floor(vim.o.columns * 0.6)`)
---@field height? integer Window height in rows. (default: `math.floor(vim.o.lines * 0.25)`)
---@field row? integer Row position. (default: `vim.o.lines - 2`)
---@field col? integer Column position. (default: `vim.o.columns`)
---@field border? string|table Border style. (default: `"rounded"`)
---@field title? string Window title. (default: `" LÖVE Output "`)
---@field title_pos? string Title alignment. (default: `"center"`)
---@field style? string Window style. (default: `"minimal"`)
---@field zindex? integer Stacking order. (default: `45`)

---Callback table passed to `vim.fn.jobstart()` by the job module.
---Wraps output panel logic (append, auto-open, diagnostics) around the raw stream callbacks.
---@class Love2D.Output.JobCallbacks
---@field on_stdout fun(job_id: integer, data: string[]): nil Appends stdout lines and auto-opens the panel on first output.
---@field on_stderr fun(job_id: integer, data: string[]): nil Appends stderr lines, pushes errors to `vim.diagnostic`, and auto-opens the panel.
---@field on_exit fun(job_id: integer, code: integer): nil Appends an exit-code footer line to the output buffer.

---------------------------------------------------------------------------
-- 5. Events
---------------------------------------------------------------------------

---Payload for the `User LoveProjectEnter` autocmd event.
---Fired when Neovim detects that the CWD is inside a LÖVE project.
---@class Love2D.Events.EnterData
---@field path_to_love2d_project string Absolute path to the detected project root.
---@field path_to_main_lua? string Absolute path to `main.lua`, or `nil` if the project has none.

---Payload for the `User LoveProjectLeave` autocmd event.
---Fired when Neovim detects that the CWD is no longer inside a LÖVE project.
---@class Love2D.Events.LeaveData
---@field path_to_love2d_project nil Always `nil` on leave.
---@field path_to_main_lua nil Always `nil` on leave.

---------------------------------------------------------------------------
-- 6. LSP Settings
---------------------------------------------------------------------------

---Top-level lua_ls settings block injected by love2d.nvim.
---@class Love2D.Lsp.Settings
---@field Lua Love2D.Lsp.LuaSettings Lua-specific configuration.

---Lua section of the lua_ls settings.
---@class Love2D.Lsp.LuaSettings
---@field runtime Love2D.Lsp.RuntimeSettings
---@field diagnostics Love2D.Lsp.DiagnosticSettings
---@field workspace Love2D.Lsp.WorkspaceSettings

---Runtime version configuration.
---@class Love2D.Lsp.RuntimeSettings
---@field version string Lua runtime version. Always `"LuaJIT"` for LÖVE projects.

---Diagnostic suppression configuration.
---@class Love2D.Lsp.DiagnosticSettings
---@field disable string[] List of diagnostic codes to suppress. Currently `{"duplicate-set-field"}` to avoid false positives from LÖVE callback re-definitions.

---Workspace configuration including type definition library paths.
---@class Love2D.Lsp.WorkspaceSettings
---@field checkThirdParty boolean Whether lua_ls prompts about third-party libraries. Always `false` for LÖVE projects.
---@field library string[] Absolute paths to type definition directories. Love2d.nvim appends its vendored LÖVE and LuaSocket library paths here.

---------------------------------------------------------------------------
-- 7. Module APIs
---------------------------------------------------------------------------

------------------------------------------------------------------------
-- love2d (init.lua) — Public API
------------------------------------------------------------------------

---Main plugin module returned by `require("love2d")`.
---@class love2d
---@field did_setup boolean Whether `setup()` has been called. Guarded — subsequent calls emit a warning.
local love2d = {}

---Initialize love2d.nvim.
---Configures options, LSP, autocmds, and event listeners.
---Guards against double calls — second invocation emits a warning and returns immediately.
---@param opts? Love2D.Config Plugin configuration table.
function love2d.setup(opts) end

------------------------------------------------------------------------
-- love2d.config (config.lua) — Configuration
------------------------------------------------------------------------

---Configuration module returned by `require("love2d.config")`.
---@class love2d.config
---@field defaults Love2D.Config Static table of default option values.
---@field options Love2D.Config Merged runtime configuration (`defaults` + user overrides).
local config = {}

---Merge user options with defaults.
---Called internally by `love2d.setup()` — should not be called directly.
---@param opts? Love2D.Config User configuration table.
function config.setup(opts) end

------------------------------------------------------------------------
-- love2d.utils (utils.lua) — Project Detection
------------------------------------------------------------------------

---Utility module returned by `require("love2d.utils")`.
---@class love2d.utils
local utils = {}

---Walk upward from CWD to find a LÖVE project root.
---Detection tiers (first match wins):
---  1. `conf.lua` containing `function love.conf`
---  2. `main.lua` with LÖVE callbacks or module usage
---  3. Any `*.lua` file in the directory with LÖVE callback definitions
---@return string? root Absolute path to the project root, or `nil` if not in a LÖVE project.
function utils.path_to_love2d_project() end

---Walk upward from CWD to find a project root (`conf.lua` or `.git/`),
---then returns the full path to `main.lua` if it exists at that root.
---@return string? main Absolute path to `main.lua`, or `nil` if not found.
function utils.path_to_main_lua() end

------------------------------------------------------------------------
-- love2d.job (job.lua) — Process Lifecycle
------------------------------------------------------------------------

---Job management module returned by `require("love2d.job")`.
---@class love2d.job
---@field state Love2D.Job.State Current job and project state.
local job = {}

---Set the current LÖVE project paths.
---Called by the autocmd handler on `User LoveProjectEnter`.
---@param path_to_love2d_project string Absolute path to the project root.
---@param path_to_main_lua string Absolute path to `main.lua`.
function job.set_project(path_to_love2d_project, path_to_main_lua) end

---Clear the current LÖVE project paths and stop everything.
---Stops watch mode, kills the running process (if any), and resets project paths.
---Called by the autocmd handler on `User LoveProjectLeave`.
function job.clear_project() end

---Run the detected LÖVE project once.
---Emits a warning notification and returns early if:
---  - no LÖVE project is detected
---  - watch mode is active (use `stop()` first)
---  - a process is already running
function job.run() end

---Run the detected LÖVE project with auto-restart on save.
---Creates a `BufWritePost *.lua` autocmd (debounced, 300 ms) that kills the
---running process and restarts it. Emits a warning and returns early if:
---  - no LÖVE project is detected
---  - already in watch mode
function job.watch() end

---Stop the running LÖVE process and/or watch mode.
---Emits a warning if nothing is running.
function job.stop() end

---Display info about the current LÖVE project and job state.
---Shows project name, entry point, run status, and last exit code (if any)
---via `vim.notify`.
function job.info() end

---Start the LÖVE process.
---Reads the entry point from `job.state.path_to_main_lua`, constructs the
---command from `config.options.path_to_love_bin`, opens the output panel,
---and launches the job with merged stdout/stderr/exit callbacks.
---@private
function job._start_process() end

---Stop watch mode (idempotent).
---Resets `watching` and `restarting` flags, bumps `watch_generation` to cancel
---pending debounced restarts, and deletes the `love2d_watch` augroup.
---@private
function job._stop_watch() end

---BufWritePost callback for watch mode.
---Kills the running process and schedules a debounced restart (300 ms).
---Stale restarts are cancelled via `watch_generation` comparison.
---@private
function job._on_save() end

------------------------------------------------------------------------
-- love2d.output (output.lua) — Floating Output Panel
------------------------------------------------------------------------

---Output panel module returned by `require("love2d.output")`.
---@class love2d.output
---@field buf integer? Buffer handle for the output scratch buffer, or `nil` if not created yet.
---@field win integer? Window handle for the output floating window, or `nil` if closed.
local output = {}

---Get the current display state of the output panel.
---@return Love2D.Output.State
function output.state() end

---Open the output window unfocused (cursor stays in the code buffer).
---No-op if the window is already open.
function output.open() end

---Close the output window, wipe the buffer, and clear all LÖVE runtime diagnostics.
function output.close() end

---Move cursor into the output window. Opens it first if hidden.
function output.focus() end

---Smart toggle for `:Love output`.
---  - `hidden`    → focused (opens and enters)
---  - `unfocused` → focused (enters existing window)
---  - `focused`   → hidden  (closes)
function output.toggle() end

---Clear buffer content. Keeps the buffer alive if it already exists.
function output.clear() end

---Append lines to the output buffer.
---Empty strings are filtered out. If the user hasn't scrolled up, the window
---auto-scrolls to show the new content.
---@param lines string[] Raw lines from the job's stdout/stderr callback.
function output.append(lines) end

---Push stderr lines to `vim.diagnostic` for inline display in source buffers.
---Parses `filename.lua:line: message` format and attaches diagnostics to
---matching loaded buffers under the `love2d_runtime` namespace.
---@param lines string[] Raw stderr lines from the LÖVE process.
function output.push_diagnostics(lines) end

---Clear all LÖVE runtime diagnostics across every buffer.
function output.clear_diagnostics() end

---Prepare the output panel for a new run.
---Clears buffer content, clears diagnostics, and stores the project root
---for file-path resolution in diagnostics and jump-to-file.
---@param root string Absolute path to the LÖVE project root.
---@param opts nil|false|Love2D.Output.WinConfig Config value of the `output` option. `false` disables auto-open; a table overrides window defaults; `nil` uses defaults.
function output.start(root, opts) end

---Mark the output as stopped.
---Intentionally a no-op — the window stays open and the exit message
---is appended by the `on_exit` callback from `job_opts()`.
function output.stop() end

---Build the `vim.fn.jobstart` option table with stream callbacks.
---Each callback appends to the output buffer, and stderr lines are also
---pushed to `vim.diagnostic`. Auto-opens the panel on first output
---(unless suppressed by config).
---@param opts nil|false|Love2D.Output.WinConfig Config value of the `output` option.
---@return Love2D.Output.JobCallbacks callbacks Options to pass to `vim.fn.jobstart()`.
function output.job_opts(opts) end

---Jump to the `file:line` under the cursor in the output buffer.
---State transitions to `unfocused` (cursor in the source file, output window stays visible).
---@private
function output._goto_file_line() end

------------------------------------------------------------------------
-- love2d.events (events.lua) — Project Detection Events
------------------------------------------------------------------------

---Event detection module returned by `require("love2d.events")`.
---@class love2d.events
local events = {}

---Set up project-detection autocmds.
---Listens to `VimEnter`, `DirChanged`, and `BufEnter` to detect when the CWD
---enters or leaves a LÖVE project. Fires `User LoveProjectEnter` and
---`User LoveProjectLeave` accordingly.
function events.setup() end

------------------------------------------------------------------------
-- love2d.autocmd (autocmd.lua) — Autocmd Handlers
------------------------------------------------------------------------

---Autocmd handler module returned by `require("love2d.autocmd")`.
---@class love2d.autocmd
local autocmd = {}

---Set up autocmds for love2d.nvim.
---Subscribes to `User LoveProjectEnter` and `User LoveProjectLeave` events:
---  - On enter: updates job state and shows a notification with project info.
---  - On leave: clears job state, closes the output panel, and notifies.
function autocmd.setup() end

------------------------------------------------------------------------
-- love2d.lsp (lsp.lua) — LSP Integration
---------------------------------------------------------------------------

---LSP integration module returned by `require("love2d.lsp")`.
---@class love2d.lsp
---@field _cached_library_paths string[]|nil Cached resolved library paths from the last `_enable()` call. Used by `_disable()` to know which paths to strip.
local lsp = {}

---Initialize LSP integration.
---Subscribes to `User LoveProjectEnter` / `User LoveProjectLeave` events
---to dynamically configure lua_ls. Calls `vim.lsp.enable("lua_ls")` once
---(no-op if already enabled by the user).
function lsp.setup() end

---Resolve absolute paths to the vendored love2d and luasocket type-definition
---libraries from the plugin's runtimepath.
---@return string[] paths Absolute paths to inject into `lua_ls` `workspace.library`.
function lsp._resolve_library_paths() end

---Read the current `workspace.library` from the resolved lua_ls config.
---@return string[] library Existing library paths. Returns `{}` if none is configured.
function lsp._get_existing_library() end

---Build the love2d-specific lua_ls settings table.
---@param library_paths string[] Absolute paths to type-definition directories.
---@return Love2D.Lsp.Settings settings A table suitable for `vim.lsp.config("lua_ls", { settings = ... })`.
function lsp._build_settings(library_paths) end

---Configure lua_ls for LÖVE development.
---Called on `User LoveProjectEnter`. Reads existing `workspace.library` paths,
---appends love paths, then merges love-specific settings into the lua_ls config chain.
function lsp._enable() end

---Remove love-specific library paths from the lua_ls config.
---Called on `User LoveProjectLeave`. Strips love paths from `workspace.library`,
---keeping user-defined paths intact, and notifies any running lua_ls clients
---via `workspace/didChangeConfiguration`.
function lsp._disable() end

------------------------------------------------------------------------
-- love2d.health (health.lua) — Health Checks
------------------------------------------------------------------------

---Health check module returned by `require("love2d.health")`.
---@class love2d.health
local health = {}

---Run health checks for `:checkhealth love2d`.
---Reports on:
---  1. Whether `setup()` was called
---  2. Neovim version (requires >= 0.12.2)
---  3. LÖVE binary availability and version
---  4. lua-language-server binary and configuration
---  5. Type-definition library submodules (love2d + luasocket)
---  6. Treesitter parsers (lua + glsl)
---  7. GLSL injection query
---  8. Plugin runtime state
function health.check() end
