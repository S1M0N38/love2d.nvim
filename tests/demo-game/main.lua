io.stdout:setvbuf("no")

-- main.lua — entry point, delegates to current state
local State = require("src.state")
local menu = require("src.states.menu")

function love.load()
  State.switch(menu)
end

function love.update(dt)
  if State.current and State.current.update then
    State.current:update(dt)
  end
end

function love.draw()
  if State.current and State.current.draw then
    State.current:draw()
  end
end

function love.keypressed(key)
  if State.current and State.current.keypressed then
    State.current:keypressed(key)
  end
end
