---@class MathModule
---@field max function: Will return the bigger number
---@field min function: Will return the smaller number
local M = {}

--- Will return the bigger number
---@param a number: first number
---@param b number: second number
---@return number: bigger number
---@see M.min
M.max = function(a, b)
  if a > b then
    return a
  end
  return b
end

--- Will return the smaller number
---@param a number: first number
---@param b number: second number
---@return number: smaller number
---@see M.max
M.min = function(a, b)
  if a < b then
    return a
  end
  return b
end

--- Will round a float number to the nearest integer
---@param num number: float number
---@return number: rounded num
---@see math.floor
---@see math.ceil
M.round = function(num)
  if num >= 0 then
    return math.floor(num + 0.5)
  else
    return math.ceil(num - 0.5)
  end
end

return M
