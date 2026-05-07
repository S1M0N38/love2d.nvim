# Type Annotations (LuaCATS) — Reference for Neovim Plugins

Comprehensive guide to LuaCATS annotations for Neovim plugin development.
Based on the [LuaLS annotation spec](https://luals.github.io/wiki/annotations/) and
[nvim-best-practices](https://github.com/lumen-oss/nvim-best-practices).

> **When to read this**: When writing type annotations for a Neovim plugin,
> creating definition files, or configuring LuaLS for type checking.

---

## Table of Contents

1. [Quick Start](#1-quick-start)
2. [Type Syntax Reference](#2-type-syntax-reference)
3. [Annotation Tags — Complete Reference](#3-annotation-tags--complete-reference)
4. [Neovim Plugin Type Patterns](#4-neovim-plugin-type-patterns)
5. [Definition Files (@meta)](#5-definition-files-meta)
6. [Config Type Patterns](#6-config-type-patterns)
7. [Diagnostic Configuration](#7-diagnostic-configuration)

---

## 1. Quick Start

### Minimum annotations every plugin needs

```lua
-- lua/yourplugin/types.lua
---@meta

---@class YourPlugin.Config
---@field enabled? boolean Whether the plugin is enabled (default: true)
---@field timeout? number Timeout in ms (default: 1000)
---@field style? "compact"|"full" Display style (default: "compact")
```

```lua
-- lua/yourplugin/init.lua
local M = {}
local config = require("yourplugin.config")

---Setup the plugin
---@param opts? YourPlugin.Config
function M.setup(opts)
  config.setup(opts)
end

---Do something
---@param bufnr? integer Buffer number (0 for current)
---@return boolean success
function M.do_thing(bufnr)
  return true
end

return M
```

### Rules of thumb

- **`@class`** for every config/options table
- **`@param`** and **`@return`** on every public function
- **`?`** for optional fields and parameters
- **Separate `types.lua`** with `---@meta` for shared type definitions
- **Namespace** class names: `YourPlugin.ClassName`

---

## 2. Type Syntax Reference

### Primitive types

```
nil  any  boolean  string  number  integer  function  table  thread  userdata  lightuserdata
```

### Compound types

| Syntax | Meaning | Example |
|--------|---------|---------|
| `TYPE?` | Optional (`TYPE \| nil`) | `string?` |
| `TYPE1 \| TYPE2` | Union | `string\|integer` |
| `TYPE[]` | Array | `string[]` |
| `(TYPE1 \| TYPE2)[]` | Union array (parens required) | `(string\|integer)[]` |
| `[T1, T2, T3]` | Tuple | `[string, integer]` |
| `{ [KEY]: VALUE }` | Dictionary | `{ [string]: boolean }` |
| `table<K, V>` | Generic table | `table<string, integer>` |
| `{ k1: T1, k2: T2 }` | Record | `{ name: string, age: integer }` |
| `fun(p: T): R` | Function | `fun(buf: integer): string` |

### Common Neovim type expressions

```lua
---@type integer                              -- buffer/window/tab IDs
---@type string[]                             -- list of filetypes
---@type { [string]: boolean }                -- set of disabled filetypes
---@type table<string, any>                   -- opaque opts table
---@type fun(bufnr: integer, winid: integer)  -- callback
---@type string|integer                       -- highlight name or ID
---@type "n"|"v"|"x"|"i"|"c"|"t"             -- mode shortname
---@type (string|integer)[]                   -- mixed ID array
```

---

## 3. Annotation Tags — Complete Reference

All annotations use the `---` prefix (three dashes). They support Markdown in descriptions.

### @class — Define a structured type

```lua
---@class [(exact)|(partial)] <name>[: <parent>[, <parent>...]]
```

- `(exact)` — prevents adding fields outside the definition
- `(partial)` — makes all inherited fields optional in the derived class
- Inheritance with `:`, multiple parents with `,`

```lua
---@class YourPlugin.Entry
---@field id integer
---@field name string

---@class YourPlugin.Highlight: YourPlugin.Entry
---@field fg string

---@class (exact) YourPlugin.StrictOpts
---@field width integer
---@field height integer
local opts = {}
-- opts.extra = true  --> WARNING with (exact)
```

### @field — Define a class field

```lua
---@field [scope] <name[?]> <type> [description]
```

Scopes: `private`, `protected`, `public`, `package`

```lua
---@class YourPlugin.State
---@field bufnr integer The buffer handle
---@field name? string Optional buffer name
---@field private _data table Internal data (not accessible outside class)
---@field protected config table Accessible in subclasses
---@field [string] any Catch-all for dynamic keys
```

### @type — Mark variable type

```lua
---@type <type>
```

```lua
---@type string[]
local filetypes = { "lua", "rust" }

---@type { [string]: boolean }
local disabled = { gitcommit = true }

---@type fun(bufnr: integer): boolean
local is_valid = function(bufnr) return vim.api.nvim_buf_is_valid(bufnr) end

---@type YourPlugin.Config
local config = {}
```

### @alias — Create a type alias

```lua
---@alias <name> <type>              -- simple alias
---@alias <name>                     -- enum-style (multi-line)
---| '"value"' [# description]
```

```lua
--- Simple alias
---@alias YourPlugin.LogLevel "trace"|"debug"|"info"|"warn"|"error"

--- Enum-style with descriptions
---@alias YourPlugin.Action
---| '"install"' # Install a plugin
---| '"sync"'    # Sync plugins
---| '"prune"'   # Remove unused plugins

--- Literal alias (references runtime variables)
local MODE_N = "n"
local MODE_V = "v"
---@alias YourPlugin.Mode `MODE_N` | `MODE_V`

--- Position type
---@alias YourPlugin.Pos {[1]: integer, [2]: integer}

--- Callback type
---@alias YourPlugin.Handler fun(err: string?, data: string): nil
```

### @enum — Define a runtime enum table

```lua
---@enum [(key)] <name>
```

Use `@enum` when you need the table at runtime (unlike `@alias` which is type-only).
Use `(key)` for key-based completion instead of value-based.

```lua
--- Value-based enum (completes with SEVERITY.error, SEVERITY.warning, etc.)
---@enum YourPlugin.Severity
local SEVERITY = {
  error = 1,
  warning = 2,
  info = 3,
}

---@param sev YourPlugin.Severity
local function set_level(sev) end
set_level(SEVERITY.error)  -- completion works

--- Key-based enum (completes with "lua", "rust", "python")
---@enum (key) YourPlugin.Filetype
local FT = {
  lua = "lua",
  rust = "rs",
  python = "py",
}

---@param ft YourPlugin.Filetype
local function detect(ft) end
detect("lua")  -- completion works
```

### @param — Document a function parameter

```lua
---@param <name[?]> <type> [description]
```

```lua
---@param bufnr integer Buffer handle (0 for current)
---@param opts? table Optional keyword arguments
---@param mode "n"|"v"|"i" Editor mode
---@param ... string Additional tag strings
function M.add_tags(bufnr, opts, mode, ...) end
```

### @return — Document a return value

```lua
---@return <type> [<name> [# comment] | [name] <comment>]
```

```lua
---@return integer bufnr The buffer handle
---@return boolean ok # true on success
---@return string|nil error Error message if failed
local function create_buf() end

--- Variable number of returns
---@return integer count Number of items
---@return string ... Item names
local function get_items() end
```

### @generic — Define generic type parameters

```lua
---@generic <name> [:parent_type]
```

```lua
--- Generic function
---@generic T
---@param list T[]
---@return T|nil
local function first(list)
  return list[1]
end
local x = first({ 1, 2, 3 }) -- x: integer

--- Generic with constraint
---@generic T: table
---@param defaults T
---@param ... T[]
---@return T
function M.merge(defaults, ...) end

--- Multiple generic parameters
---@generic K, V
---@param t table<K, V>
---@return fun(): K, V
local function my_pairs(t) end

--- Backtick capture (captures string value as type name)
---@generic T
---@param class `T`
---@return T
local function create(class) end
local obj = create("MyHandler") -- obj: MyHandler

--- Generic container class
---@class YourPlugin.List<T>: { [integer]: T }
---@type YourPlugin.List<string>
local names = {}
```

### @overload — Additional function signature

```lua
---@overload fun([param: type[, ...]]): [return]
```

```lua
---@param bufnr integer Buffer handle
---@param opts? table Optional options
---@return string name
---@overload fun(bufnr: integer): string
function M.get_name(bufnr, opts) end

-- Both calls get completion:
M.get_name(0)
M.get_name(0, { raw = true })
```

> **Prefer multiple function declarations over `@overload`** in definition files.

### @operator — Operator metamethod types

```lua
---@operator <op>[(param_type)]: return_type
```

Supported: `add`, `sub`, `mul`, `div`, `mod`, `pow`, `unm`, `concat`, `len`, `eq`, `lt`, `le`, `call`, `tostring`

```lua
---@class YourPlugin.Position
---@field row integer
---@field col integer
---@operator add(YourPlugin.Position): YourPlugin.Position
---@operator sub(YourPlugin.Position): YourPlugin.Position
---@operator unm: YourPlugin.Position

---@type YourPlugin.Position
local p1, p2
local p3 = p1 + p2  -- p3: YourPlugin.Position
local p4 = -p1      -- p4: YourPlugin.Position
```

### @cast — Change a variable's type

```lua
---@cast <name> [+|-]<type|?>[, ...]
```

```lua
---@type string|integer
local val = "hello"
---@cast val string        -- now string only

---@type string
local name
---@cast name +?           -- now string? (adds nil)

---@type string|boolean|integer
local x
---@cast x -boolean        -- now string|integer (removes boolean)
```

### @as — Inline type cast on an expression

```lua
--[[@as <type>]]
```

```lua
local name = vim.api.nvim_buf_get_name(0) --[[@as string]]

-- For array types, use [=[ ]=] to avoid bracket parsing issues:
local items = some_func() --[=[@as string[]]=]
```

### Visibility modifiers

| Tag | Scope | Accessible from |
|-----|-------|----------------|
| `@private` | Class | Only within the class (NOT child classes) |
| `@protected` | Class | Class AND child classes |
| `@package` | File | Only within the same file |
| `@public` | Explicit | Anywhere (overrides inherited restriction) |

```lua
---@class YourPlugin.Manager
---@field private _state table Internal state
---@field protected config table Accessible in subclasses
---@field public name string Explicitly public
local Manager = {}

---@private
function Manager:_reset() end

---@protected
function Manager:_validate() end

---@package
function Manager._helper() end
```

### Other tags

| Tag | Syntax | Purpose |
|-----|--------|---------|
| `@async` | `---@async` | Mark function as async (enables await hints) |
| `@deprecated` | `---@deprecated` | Mark as deprecated (strikethrough + diagnostic) |
| `@nodiscard` | `---@nodiscard` | Warn if return value is ignored |
| `@see` | `---@see <symbol>` | Hyperlink to another symbol |
| `@source` | `---@source <path>[:line[:col]]` | Link to source in another file |
| `@module` | `---@module 'name'` | Simulate `require` without loading |
| `@version` | `---@version <version>` | Lua version constraint (5.1, 5.2, JIT) |
| `@diagnostic` | `---@diagnostic <state>:<code>` | Toggle diagnostics inline |

### @diagnostic — Inline diagnostic control

```lua
---@diagnostic disable-next-line: unused-local
local _ = "intentionally unused"

---@diagnostic disable: undefined-field
vim.g.my_plugin = vim.g.my_plugin
---@diagnostic enable: undefined-field
```

States: `disable-next-line`, `disable-line`, `disable`, `enable`

---

## 4. Neovim Plugin Type Patterns

### Autocmd callbacks

```lua
--- Autocmd callback — use Neovim's built-in type
---@alias YourPlugin.AutocmdCb fun(ev: vim.api.keyset.event): boolean?

---@param event string|string[]
---@param callback YourPlugin.AutocmdCb
---@param opts? { pattern?: string|string[], buffer?: integer, group?: string|integer }
function M.on_event(event, callback, opts) end
```

### Keymaps

```lua
---@alias YourPlugin.Mode "n"|"v"|"x"|"s"|"o"|"i"|"c"|"t"

---@class YourPlugin.KeymapDef
---@field mode YourPlugin.Mode|YourPlugin.Mode[]
---@field lhs string
---@field rhs string|fun(): nil
---@field desc? string
---@field buffer? integer|boolean
---@field silent? boolean
---@field nowait? boolean
---@field expr? boolean
---@field noremap? boolean
```

### Highlight groups

```lua
```lua
---@class YourPlugin.HighlightOpts
---@field fg? string|integer Foreground color
---@field bg? string|integer Background color
---@field link? string Link to another highlight group
---@field default? boolean Don't override existing definition
---@field bold? boolean
---@field italic? boolean
---@field underline? boolean
---@field undercurl? boolean
---@field underdouble? boolean
---@field underdotted? boolean
---@field underdashed? boolean
---@field strikethrough? boolean
---@field nocombine? boolean
---@field blend? integer 0–100 blend level
---@field sp? string|integer Special color (for underline/undercurl)
```

### Buffer/Window management

```lua
---@class YourPlugin.FloatWin
---@field buf? integer Buffer handle
---@field win? integer Window handle
---@field buf_valid fun(self: YourPlugin.FloatWin): boolean
---@field win_valid fun(self: YourPlugin.FloatWin): boolean
---@field valid fun(self: YourPlugin.FloatWin): boolean
---@field open fun(self: YourPlugin.FloatWin, opts?: vim.api.keyset.win_config): integer
---@field close fun(self: YourPlugin.FloatWin): nil
```

### LSP integration

```lua
---@param buf integer
---@param method string
---@return vim.lsp.Client[]
function M.get_clients(buf, method) end

---@alias YourPlugin.LspHandler fun(err: vim.lsp.protocol.ResponseError?, result: any, ctx: vim.lsp.HandlerContext, config?: table)

---@param buf integer
---@param method string
---@param params table
---@param handler YourPlugin.LspHandler
function M.request(buf, method, params, handler) end
```

### User commands with subcommands

```lua
---@class YourPlugin.Subcommand
---@field impl fun(args: string[], opts: table) The command implementation
---@field complete? fun(arg_lead: string): string[] Optional completions

---@type table<string, YourPlugin.Subcommand>
local subcommands = {
  install = {
    impl = function(args, opts) end,
    complete = function(arg_lead)
      return vim.iter({ "plugin-a", "plugin-b" })
        :filter(function(name) return name:find(arg_lead) ~= nil end)
        :totable()
    end,
  },
}
```

### Debounced/throttled functions

```lua
---@param ms integer Debounce delay in milliseconds
---@param fn fun(...: any): ...:any
---@return fun(...: any)
function M.debounce(ms, fn) end
```

### Generic utility wrappers

```lua
---@generic T: table
---@param defaults T
---@param ... T[]
---@return T
function M.merge(defaults, ...) end

---@generic T
---@param list T[]
---@param predicate fun(item: T): boolean
---@return T|nil
function M.find_first(list, predicate) end

---@generic T
---@param list T[]
---@param mapper fun(item: T, idx: integer): any
---@return any[]
function M.map(list, mapper) end
```

---

## 5. Definition Files (@meta)

### What is a definition file?

A `.lua` file marked `---@meta` that contains **only type declarations** (no runtime code).
LuaLS reads it for type information but it is not executed.

### Naming and placement

```
lua/yourplugin/
  types.lua     ← @meta file, never required at runtime
  init.lua      ← main module
  config.lua    ← config module
```

### Basic structure

```lua
---@meta
--- Type definitions for yourplugin.nvim

---------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------

---@class YourPlugin.Config
---@field enabled? boolean Whether the plugin is enabled
---@field timeout? number Timeout in milliseconds
---@field on_attach? fun(bufnr: integer, ft: string) Buffer-local callback

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

---@class YourPlugin.API
---@field setup fun(opts?: YourPlugin.Config)
---@field toggle fun(): boolean
---@field get_items fun(bufnr?: integer): YourPlugin.Item[]
```

### @meta options

```lua
---@meta             -- generic meta file
---@meta myModule    -- only requireable as "myModule"
---@meta _           -- cannot be required at all (recommended for type-only files)
```

### Class hierarchies in definition files

```lua
---@meta

---@class YourPlugin.Highlight
---@field fg? string
---@field bg? string

---@class YourPlugin.HighlightWithLink: YourPlugin.Highlight
---@field link? string

---@class (exact) YourPlugin.StrictConfig
---@field name string
---@field count integer
```

### Method signatures (colon vs dot)

```lua
---@meta

---@class YourPlugin.Server
local Server = {}

--- Instance method (colon syntax, receives self)
---@param payload string
---@return boolean ok
function Server:send(payload) end

--- Static factory (dot syntax)
---@param host string
---@param port integer
---@return YourPlugin.Server
function Server.new(host, port) end
```

---

## 6. Config Type Patterns

### Pattern A: Separate classes (recommended — clear and explicit)

Define two classes: one for the user (all optional) and one for internal use (all required).

```lua
-- lua/yourplugin/types.lua
---@meta _

---@class YourPlugin.Config
---@field do_something_cool? boolean
---@field strategy? "random"|"periodic"

-- lua/yourplugin/config.lua

---@class YourPlugin.InternalConfig
local default_config = {
  ---@type boolean
  do_something_cool = true,
  ---@type "random" | "periodic"
  strategy = "random",
}

---@param opts? YourPlugin.Config
---@return YourPlugin.InternalConfig
function M.setup(opts)
  ---@type YourPlugin.InternalConfig
  local config = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
  return config
end
```

### Pattern B: (partial) class (less boilerplate)

The `(partial)` attribute makes all fields of a class nullable.

```lua
---@class YourPlugin.Config
---@field do_something_cool boolean
---@field strategy "random"|"periodic"

-- (partial) makes all fields of YourPlugin.Config optional
---@class (partial) YourPlugin.Opts: YourPlugin.Config

---@type YourPlugin.Opts | fun():YourPlugin.Opts | nil
vim.g.your_plugin = vim.g.your_plugin

---@type YourPlugin.Config
local defaults = { do_something_cool = true, strategy = "random" }

---@type YourPlugin.Config
local config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_config)
```

> **Caveat**: `vimdoc` generators may not support `(partial)`, and it exposes the internal class name.

### Config validation

```lua
---@param cfg YourPlugin.InternalConfig
---@return boolean ok
---@return string|nil err
function M.validate(cfg)
  local ok, err = pcall(vim.validate, {
    do_something_cool = { cfg.do_something_cool, "boolean" },
    strategy = { cfg.strategy, "string" },
  })
  return ok, err
end
```

### User-facing global config pattern

```lua
---@type YourPlugin.Opts | fun():YourPlugin.Opts | nil
vim.g.your_plugin = vim.g.your_plugin

local user_config = type(vim.g.your_plugin) == "function"
    and vim.g.your_plugin()
    or vim.g.your_plugin
    or {}
```

---

## 7. Diagnostic Configuration

### Recommended `.luarc.json` for Neovim plugins

```json
{
  "runtime.version": "LuaJIT",
  "diagnostics.globals": ["vim"],
  "type.castNumberToInteger": true,
  "type.checkTableShape": true,
  "workspace.library": [
    "./lua/",
    "${3rd}/luv/library"
  ],
  "workspace.checkThirdParty": false,
  "type.castTypeToAny": "Disable"
}
```

### Key type-checking settings

| Setting | Default | Recommended | Purpose |
|---------|---------|-------------|---------|
| `type.castNumberToInteger` | `false` | `true` | Allow `number` → `integer` (buffer IDs) |
| `type.checkTableShape` | `false` | `true` | Strict table field checking |
| `type.inferParamType` | `false` | `false` | Infer param types from call sites |
| `type.weakNilCheck` | `false` | `false` | Allow `T\|nil` → `T` |
| `type.weakUnionCheck` | `false` | `false` | Allow `A\|B` → `A` |

### Most relevant diagnostics for plugin dev

| Diagnostic | Group | Triggers when |
|------------|-------|---------------|
| `assign-type-mismatch` | type-check | Wrong type assigned to variable |
| `cast-local-type` | type-check | Local changes type after init |
| `param-type-mismatch` | type-check | Wrong argument type |
| `return-type-mismatch` | type-check | Wrong return type |
| `need-check-nil` | type-check | Indexing a possibly-nil value |
| `undefined-field` | type-check | Accessing undeclared class field |
| `missing-fields` | unbalanced | Class instance missing required field |
| `missing-parameter` | unbalanced | Missing required function argument |
| `missing-return` | unbalanced | Function missing declared return |
| `redundant-parameter` | unbalanced | Extra function argument |
| `inject-field` | type-check | Adding field to non-`(exact)` class |

### Common suppressions

```lua
---@diagnostic disable-next-line: undefined-field
vim.g.my_plugin = vim.g.my_plugin   -- dynamic vim.g fields

---@diagnostic disable-next-line: unused-local
local _ = "intentionally unused"

---@diagnostic disable-next-line: param-type-mismatch
local result = some_untyped_call()  -- third-party API
```

### Diagnostic file status

Each diagnostic can be set to:
- `"Any"` — runs on all loaded files (strictest)
- `"Opened"` — only on currently open files (default for most)
- `"None"` — disabled

---

## Quick Reference Card

```
ANNOTATION          SYNTAX                                      USE FOR
@class              @class [(exact)|(partial)] Name[:Parent]      Config, state, API types
@field              @field [scope] name[?] type [desc]          Class fields
@type               @type type                                  Variable annotations
@alias              @alias Name type                            Callbacks, positions, modes
@enum               @enum [(key)] Name                          Runtime constant tables
@param              @param name[?] type [desc]                  Function parameters
@return             @return type [name [# desc]]                Function returns
@generic            @generic T[:parent]                         Reusable generic functions
@overload           @overload fun(...): ...                     Alternative signatures
@operator           @operator op(type): type                    Metamethod type inference
@cast               @cast name [+|-]type                        Change variable type
@meta               @meta [_]                                   Definition file marker
@diagnostic         @diagnostic state:code                      Inline diagnostic control
@deprecated         @deprecated                                 Mark deprecated API
@nodiscard          @nodiscard                                  Require return capture
@async              @async                                      Mark async functions
```
