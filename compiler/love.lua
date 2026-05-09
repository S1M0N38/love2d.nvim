if vim.g.current_compiler == "love" then
  return
end
vim.g.current_compiler = "love"

-- Try to get the configured love binary path
local love_bin = "love"
local ok, config = pcall(require, "love2d.config")
if ok and config.options and config.options.path_to_love_bin then
  love_bin = config.options.path_to_love_bin
end

vim.bo.makeprg = love_bin .. " ."

-- Errorformat for LÖVE error messages.
-- The conf.lua errorhandler injects "error:" between line and message
-- so %trror captures the type (e=error) for quickfix severity display.
-- %-G%.%# discards any other output (boot messages, etc.)
--
-- NOTE: For `:make` to complete on error, your conf.lua must override
-- love.errorhandler to exit immediately. See :help love2d-compiler.
local efm = {
  "%f:%l: %trror: %m", -- file:line: error: message
  "%-G%.%#", -- discard everything else
}
vim.bo.errorformat = table.concat(efm, ",")
