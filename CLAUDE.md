# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `love2d.nvim`, a Neovim plugin that provides development support for LÖVE 2D game development. The plugin enables LSP integration, game execution controls, and enhanced development workflow for LÖVE projects.

## Development Commands

### Testing
- `busted` - Run all tests using Busted framework
- Tests require `nlua` and `busted` to be installed

### Linting
- `luacheck lua/` - Run luacheck on the lua/ directory to check code quality

### Manual Testing
- Open `tests/game/main.lua` to test the plugin with a sample LÖVE project
- Use `:LoveRun tests/game` to test game execution functionality

## Architecture

### Core Components

**Main Module (`lua/love2d/init.lua`)**
- `love2d.setup(opts)` - Plugin initialization with configuration
- `love2d.run(path)` - Start a LÖVE game project using vim.fn.jobstart
- `love2d.stop()` - Stop the running game process
- `love2d.find_src_path(path)` - Locate main.lua in project structure
- Job management with optional debug window support

**Configuration (`lua/love2d/config.lua`)**
- LSP setup using `vim.lsp.config` (Nvim 0.11+ style configuration)
- Love2D project auto-detection via main.lua presence or `love.` function usage
- Library path validation and management for LÖVE and LuaSocket libraries
- Auto-restart functionality on file save

### Key Architecture Patterns

**LSP Integration Strategy**
- Uses `vim.lsp.config.lua_ls` for modern Nvim 0.11+ LSP configuration
- Merges with existing lua_ls settings using `vim.tbl_deep_extend`
- Adds LÖVE library paths to workspace.library configuration
- Configures Lua 5.1 runtime and "love" global for diagnostics

**Project Detection Logic**
- Primary: Check for `main.lua` file in current directory
- Secondary: Scan `*.lua` files for `love.` function calls to identify LÖVE projects
- Controlled by `identify_love_projects` option (default: true)

**Job Management**
- Single concurrent game instance enforcement
- Optional debug window integration for stdout capture
- Proper cleanup on job termination

## File Structure

- `lua/love2d/` - Main plugin code
- `love2d/library/` - LÖVE API definitions for LSP
- `luasocket/` - LuaSocket library definitions
- `after/queries/lua/injections.scm` - Treesitter injection for GLSL in LÖVE shaders
- `spec/` - Test suite using Busted framework
- `tests/game/` - Sample LÖVE game for testing plugin functionality
- `doc/love2d.txt` - Complete plugin documentation

## Configuration Options

Key options to understand when modifying the plugin:
- `path_to_love_bin` - LÖVE executable path
- `identify_love_projects` - Auto-detect LÖVE projects before LSP setup
- `debug_window_opts` - Optional stdout capture window configuration
- `restart_on_save` - Auto-restart game on Lua file changes

The plugin always uses bundled LÖVE and LuaSocket library definitions for LSP support - no manual path configuration is needed.

## Testing Approach

Tests use Busted framework with `nlua` for Neovim integration and platform-specific LÖVE binary paths. Test coverage includes:
- Game execution with valid/invalid paths
- Job lifecycle management (start/stop/prevent duplicates)
- Platform compatibility (macOS/Linux)
- LSP configuration tests are currently marked as pending due to setup complexity
