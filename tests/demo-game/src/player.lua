-- src/player.lua
local Entity = require("src.entity")

local Player = Entity:extend()

function Player:new(x, y)
  Player.super.new(self, x, y)
  self.speed = 200

  -- Inline GLSL shader: monochrome pulse glow
  self.shader = love.graphics.newShader(
    [[
      vec4 position(mat4 transform_projection, vec4 vertex_position) {
        return transform_projection * vertex_position;
      }
    ]],
    [[
      uniform float uTime;

      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        float pulse = sin(uTime * 3.0) * 0.5 + 0.5;
        float brightness = mix(0.35, 1.0, pulse);
        return vec4(vec3(brightness), color.a);
      }
    ]]
  )
end

function Player:update(dt)
  if love.keyboard.isDown("left", "a", "h") then
    self.x = self.x - self.speed * dt
  end
  if love.keyboard.isDown("right", "d", "l") then
    self.x = self.x + self.speed * dt
  end
  if love.keyboard.isDown("up", "w", "k") then
    self.y = self.y - self.speed * dt
  end
  if love.keyboard.isDown("down", "s", "j") then
    self.y = self.y + self.speed * dt
  end
  -- Out of bounds detection
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  if self.x < 0 or self.x > w or self.y < 0 or self.y > h then
    local directions = {
      "north",
      "south",
      "east",
      "west",
    }
    local i = math.floor(self.y / h) * 2 + math.floor(self.x / w) + 1
    local dir = directions[i]
    -- The following line introduce a deliberate runtime error (nil value concatenation)
    print("player went off-screen: " .. dir)
  end

  print(string.format("x: %.0f  y: %.0f", self.x, self.y))
end

function Player:draw()
  love.graphics.setColor(1, 1, 1, 1)
  self.shader:send("uTime", love.timer.getTime())
  love.graphics.setShader(self.shader)
  love.graphics.rectangle("fill", self.x, self.y, 16, 16)
  love.graphics.setShader()
end

return Player
