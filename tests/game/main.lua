-- This is required to live update the debug window using print for debug
io.stdout:setvbuf("no")

-- Create triangle mesh
local attributes = {
  { "VertexPosition", "float", 2 },
  { "VertexColor", "byte", 4 },
}
local vertices = {
  { -0.5, -0.5, 1, 0, 0 },
  { 0.5, -0.5, 0, 1, 0 },
  { 0, 0.5, 0, 0, 1 },
}
local triangle = love.graphics.newMesh(attributes, vertices, "triangles", "static")

-- If you have install glsl parser with TreeSitter, the multi-line string will be
-- highlighted like the rest of the code.
-- See `:help love2d-glsl`
local shader = love.graphics.newShader(
  [[
    varying vec4 vColor;
    vec4 position( mat4 transform_projection, vec4 vertex_position ) {
        vColor = VertexColor;
        return transform_projection * vertex_position;
    }
  ]],
  [[
    varying vec4 vColor;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        return vColor;
    }
  ]]
)

local printTimer = 0
local printInterval = 1

function love.update(dt)
  printTimer = printTimer + dt
  if printTimer >= printInterval then
    print("One second has passed. Current timer value: " .. printTimer)
    printTimer = printTimer - printInterval
  end
end

function love.draw()
  love.graphics.setShader(shader)
  love.graphics.draw(triangle, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, 200, 200)
  love.graphics.setShader()
end
