-- bad-game/main.lua — Intentional LSP warnings and runtime errors
-- for testing love2d.nvim's quickfix and diagnostics integration.

local unused_var = 42 -- LSP: unused local variable

function love.load()
  local name = nil
  -- Runtime error: attempt to concatenate a nil value (dynamic)
  -- lua_ls does not flag this because `name` could be a string at runtime.
  print("Hello, " .. name .. "!")
end
