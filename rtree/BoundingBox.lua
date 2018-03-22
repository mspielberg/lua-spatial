--[[
  [1] = left,
  [2] = top,
  [3] = right,
  [4] = bottom,
]]
local M = {}

local function min(a, b)
  if a < b then
    return a
  end
  return b
end

local function max(a, b)
  if a > b then
    return a
  end
  return b
end

function M:clone()
  return M.new(self[1], self[2], self[3], self[4])
end

function M:centroid()
  return {(self[1] + self[3]) / 2, (self[2] + self[4]) / 2}
end

function M:area()
  return (self[3] - self[1]) * (self[4] - self[2])
end

function M:margin()
  return 2 * ((self[3] - self[1]) + (self[4] - self[2]))
end

function M:contains(other)
  return self[1] <= other[1] and self[2] <= other[2] and self[3] >= other[3] and self[4] >= other[4]
end

function M:enlarge_in_place(other)
  if self == M.EMPTY then
    error("attempted to modify EMPTY")
  end
  self[1] = min(self[1], other[1])
  self[2] = min(self[2], other[2])
  self[3] = max(self[3], other[3])
  self[4] = max(self[4], other[4])
end

function M:enlarge(other)
  if other == M.EMPTY then
    return self
  end
  local out = self:clone()
  out:enlarge_in_place(other)
  return out
end

function M:intersect(other)
  return M.new(
    max(self[1], other[1]),
    max(self[2], other[2]),
    min(self[3], other[3]),
    min(self[4], other[4])
  )
end

function M:tostring()
  if self == M.EMPTY then
    return "EmptyBB()"
  end
  return "BB("..self[1]..","..self[2]..","..self[3]..","..self[4]..")"
end

local meta = {
  name = "BoundingBox",
  __index = M,
  __tostring = M.tostring,
}

M.EMPTY = setmetatable({math.huge, math.huge, -math.huge, -math.huge}, meta)

function M.new(left, top, right, bottom)
  if left > right or top > bottom then
    return M.EMPTY
  end
  return setmetatable({left, top, right, bottom}, meta)
end

return M