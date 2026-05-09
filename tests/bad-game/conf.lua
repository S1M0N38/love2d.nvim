function love.conf(t)
  t.window.title = "love2d.nvim — bad game"
end

-- Override love.errorhandler for `:make` quickfix integration.
--
-- The default errorhandler opens a graphical error window and never exits,
-- which hangs `:make`. This replacement writes a parseable error to stderr
-- and exits immediately, so errors appear in the quickfix list.
--
-- Output to stderr:
--   file:line: error: message  <- parsed by errorformat %trror
--
-- Compatible with LÖVE 0.10+ (where love.errorhandler was introduced).
-- Drop this function in your project's conf.lua to enable `:make`.
love.errorhandler = function(msg)
  msg = tostring(msg)

  -- Extract file, line, and message from the error string.
  -- LÖVE error messages follow the pattern: [prefix]file:line: message
  -- where prefix may be "Error: " or "Syntax error: ".
  local file, line, message = msg:match("(%S+):(%d+):%s+(.*)")
  if file and line then
    -- Reconstruct with explicit severity for errorformat %trror
    io.stderr:write(file .. ":" .. line .. ": error: " .. message:gsub("\n.*", "") .. "\n")
  else
    -- Fallback: write raw first line if pattern doesn't match
    local first_line = msg:match("^(.-)\n") or msg
    io.stderr:write(first_line .. "\n")
  end

  io.stderr:flush()
  os.exit(1)
end
