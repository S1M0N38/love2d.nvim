-- src/entity.lua — base class for all game objects
local Class = require("lib.classic")

local Entity = Class:extend()

function Entity:new(x, y)
  self.x = x or 0
  self.y = y or 0
end

function Entity:update(dt) end
function Entity:draw() end

return Entity
