-- src/states/menu.lua
local State = require("src.state")
local play = require("src.states.play")

local menu = {}

function menu:draw()
  love.graphics.printf("Press ENTER to start", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
end

function menu:keypressed(key)
  if key == "return" or key == "space" then
    State.switch(play)
  elseif key == "escape" then
    love.event.quit()
  end
end

return menu
