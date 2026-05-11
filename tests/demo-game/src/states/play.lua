-- src/states/play.lua
local Player = require("src.player")

local play = {}
local player

function play:enter()
  player = Player(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
end

function play:update(dt)
  player:update(dt)
end

function play:draw()
  player:draw()
end

function play:keypressed(key)
  -- add game logic here
end

function play:leave()
  player = nil
end

return play
