if vim.g.current_compiler then
  return
end
vim.g.current_compiler = "love"

-- Resolve love binary path from plugin config (if set up), else default.
local love_bin = "love"
local ok, config = pcall(require, "love2d.config")
if ok and config.options and config.options.path_to_love_bin then
  love_bin = config.options.path_to_love_bin
end

-- Resolve source path from detected project state.
-- Falls back to "." if the plugin hasn't detected a project yet.
-- Re-run `:compiler love` after detection to pick up the path.
local src = "."
local ok2, job = pcall(require, "love2d.job")
if ok2 and job.state and job.state.path_to_main_lua then
  src = vim.fn.fnamemodify(job.state.path_to_main_lua, ":h")
end

vim.cmd("CompilerSet makeprg=" .. vim.fn.escape(love_bin .. " " .. src, " \\"))

-- Errorformat for LÖVE error messages produced by the recommended
-- conf.lua errorhandler pattern:
--
--   file:line: error: message
--
-- %trror captures severity (e=error) for quickfix display.
-- %-G%.%# discards all other output (boot messages, etc.)
--
-- NOTE: LÖVE's default errorhandler opens a graphical window and never
-- exits, which hangs `:make`. You must override love.errorhandler in your
-- project's conf.lua to write parseable errors to stderr and exit.
-- See :help love2d-compiler for the recommended pattern.
vim.cmd("CompilerSet errorformat=%f:%l:\\ %trror:\\ %m,%-G%.%#")

vim.notify("Command: " .. love_bin .. "\nSource:   " .. src, vim.log.levels.INFO, { title = "love2d compiler" })
