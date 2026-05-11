function love.conf(t)
  t.version = "11.5"
  t.identity = "my-game"
  t.appendidentity = false

  t.window.title = "game"
  t.window.width = 800
  t.window.height = 600
  t.window.minwidth = 400
  t.window.minheight = 300
  t.window.resizable = true
  t.window.borderless = false
  t.window.fullscreen = false
  t.window.fullscreentype = "desktop"
  t.window.vsync = 1
  t.window.display = 1
  t.window.highdpi = false
  t.console = false

  -- Disable unused modules to reduce memory
  t.modules.physics = false
  t.modules.thread = false
end

love.errorhandler = function(msg)
  msg = tostring(msg)
  local file, line, message = msg:match("(%S+):(%d+):%s+(.*)")
  if file and line then
    io.stderr:write(file .. ":" .. line .. ": error: " .. message:gsub("\n.*", "") .. "\n")
  else
    local first_line = msg:match("^(.-)\n") or msg
    io.stderr:write(first_line .. "\n")
  end
  io.stderr:flush()
  os.exit(1)
end
