---
name: nvim-plugin
description: >
  Neovim plugin development best practices and patterns for love2d.nvim. Use when
  planning, editing, implementing, or reviewing Neovim Lua plugin code — structuring
  a new plugin, writing setup/config, highlights, autocmds, keymaps, health checks,
  type annotations, debounce, state management, or user commands. Also use when the
  user asks about plugin architecture, conventions, or "how should I implement" a
  Neovim plugin feature. Do not use for general Lua development unrelated to Neovim
  plugins, Neovim configuration (init.lua), or running/debugging tests (use nvim-test).
---

# Neovim Plugin Development (love2d.nvim)

This skill provides patterns and best practices for Neovim plugin development,
tailored to the love2d.nvim project.

Read the reference files below on demand based on the current task.

## Reference Files

Read these on demand based on the task. Do NOT load all three at once.
Each file has a table of contents at the top with anchors for navigation.

### `references/RECIPES.md`
Complete code examples for every plugin pattern.

1. Project Structure
2. Setup & Configuration
3. Module Organization
4. Plugin File (user commands, lazy loading)
5. Highlight Groups
6. Autocmds
7. Keymaps
8. Health Checks
9. Error Handling & Notifications
10. Type Annotations
11. Debounce
12. State Management (per-buffer cache)
13. User Commands
14. Anti-Patterns

### `references/TYPES.md`
LuaCATS type annotation reference for Neovim plugins.

1. Quick Start (minimum annotations every plugin needs)
2. Type Syntax Reference (primitives, compound types, Neovim-specific)
3. Annotation Tags — Complete Reference
4. Neovim Plugin Type Patterns
5. Definition Files (@meta)
6. Config Type Patterns
7. Diagnostic Configuration

### `references/TESTS.md`
Testing patterns for writing and implementing tests (mini.test).
For running tests and diagnosing failures, use the `nvim-test` skill.

1. Test File Structure
2. Assertions Quick Reference
3. Table-Driven Tests
4. Stubbing and Restoring
5. Creating Test Buffers
6. Testing with File Buffers
7. Testing Config Changes
8. Conditional Tests
9. Testing Notifications
10. Testing Highlights
11. Testing Autocmds
12. Testing Keymaps
13. Test Anti-Patterns
14. Advanced Testing Patterns

## Working with love2d.nvim

When modifying this plugin:

1. Read the existing code first — match the project's conventions
2. Check `AGENTS.md` for project-specific rules and file structure
3. Look at existing `tests/*_spec.lua` files to match testing style
4. Look at existing autocmd patterns in `lua/love2d/autocmd.lua`

### Architecture Notes

- **Module dispatch** — `init.lua` is a thin dispatcher. `setup()` calls
  `config`, `lsp`, `autocmd`, and `events` modules. No logic lives in init.
- **Job management** — `love2d.job` module manages process lifecycle (run,
  watch, stop). Single concurrent instance via `job.state.id`.
- **Output panel** — `love2d.output` module manages a floating window for
  LÖVE stdout/stderr with inline diagnostics via `vim.diagnostic`.
- **Event-driven** — `love2d.events` detects project enter/leave and fires
  `User EnterLove2DProject`/`LeaveLove2DProject`. Other modules subscribe.
- **LSP integration** — `love2d.lsp` dynamically injects/removes LÖVE library
  paths on project enter/leave. Uses `vim.lsp.config` config-chain merge.
- **Project detection** — `love2d.utils` walks up from CWD to find a LÖVE root
  (conf.lua with `love.conf`, main.lua with LÖVE callbacks/modules).
- **Vendored libraries** — Do NOT edit `libraries/love2d/` or `libraries/luasocket/`.
  These are git submodules with LÖVE/LuaSocket type definitions.

## File locations in this project

- Plugin source: `lua/love2d/`
- Tests: `tests/` (mini.test)
- Plugin commands: `plugin/love2d.lua`
- Compiler: `compiler/love.lua`
- LSP base config: `lsp/lua_ls.lua`
- Documentation: `doc/love2d.txt`
- LÖVE API definitions: `libraries/love2d/`
- LuaSocket definitions: `libraries/luasocket/`
- Treesitter injections: `after/queries/lua/injections.scm`
- Output syntax: `after/syntax/love2d_output.vim`
- Sample game: `tests/demo-game/`
