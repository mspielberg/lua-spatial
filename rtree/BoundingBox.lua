--[[
An N-dimensional hyperrectangle.

The N-th axis lower bound resides at index 2*N - 1, with the upper bound at
index 2*N.

For a 2-D rectangle with axes in X,Y order and +Y in the downwards direction,
that maps to:

{
  [1] = left,
  [2] = right,
  [3] = top,
  [4] = bottom,
}
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
  return M.new(self)
end

function M:centroid()
  local out = {}
  for axis=1,#self/2 do
    local lower = 2 * axis - 1
    local upper = lower + 1
    out[axis] = (self[lower] + self[upper]) / 2
  end
  return out
end

function M:area()
  local out = 1
  for lower=1,#self,2 do
    local upper = lower + 1
    out = out * (self[upper] - self[lower])
  end
  return out
end

function M:margin()
  local out = 0
  for lower=1,#self,2 do
    local upper = lower + 1
    out = out + (self[upper] - self[lower])
  end
  return out * 2
end

function M:intersects(other)
  if other == M.EMPTY then
    return false
  end
  for lower=1,#self,2 do
    local upper = lower + 1
    if self[lower] > other[upper] or self[upper] < other[lower] then
      return false
    end
  end
  return true
end

function M:contains(other)
  if other == M.EMPTY then
    return false
  end
  for lower=1,#self,2 do
    local upper = lower + 1
    if self[lower] > other[lower] or self[upper] < other[upper] then
      return false
    end
  end
  return true
end

-- enlarge_in_place sets self to the MBR of the union of self and other.
function M:enlarge_in_place(other)
  if other == M.EMPTY then
    return
  end
  for lower=1,#self,2 do
    local upper = lower + 1
    if other[lower] < self[lower] then
      self[lower] = other[lower]
    end
    if other[upper] > self[upper] then
      self[upper] = other[upper]
    end
  end
end

-- enlarge returns a new BoundingBox that is the MBR of the union of self and
-- other.
function M:enlarge(other)
  local out = self:clone()
  out:enlarge_in_place(other)
  return out
end

-- enlarged_area returns the equivalent of enlarge(other):area() without
-- allocating a new BoundingBox.
function M:enlarged_area(other)
  if other == M.EMPTY then
    return self:area()
  end
  local area = 1
  for lower=1,#self,2 do
    local upper = lower + 1
    local l = self[lower] < other[lower] and self[lower] or other[lower]
    local u = self[upper] > other[upper] and self[upper] or other[upper]
    area = area * (u - l)
  end
  return area
end

-- intersect returns a new BoundingBox that is the intersection of self and
-- other.
function M:intersect(other)
  if other == M.EMPTY then
    return M.EMPTY
  end
  local bounds = {}
  for lower=1,#self,2 do
    local upper = lower + 1
    bounds[lower] = max(self[lower], other[lower])
    bounds[upper] = min(self[upper], other[upper])
  end
  return M.new(bounds)
end

-- intersect_area returns the equivalent of intersect(other):area() without
-- allocating a new BoundingBox.
function M:intersect_area(other)
  if other == M.EMPTY then
    return 0
  end
  local area = 1
  for lower=1,#self,2 do
    local upper = lower + 1
    local l = self[lower] > other[lower] and self[lower] or other[lower]
    local u = self[upper] < other[upper] and self[upper] or other[upper]
    if u <= l then
      return 0
    end
    area = area * (u - l)
  end
  return area
end

function M:tostring()
  local min_coord = {}
  local max_coord = {}
  for i=1,#self/2 do
    min_coord[i] = self[2 * i - 1]
    max_coord[i] = self[2 * i]
  end
  return "BB("..table.concat(min_coord, ",")..";"..table.concat(max_coord, ",")..")"
end

-- model empty bounding box as a subclass
local EmptyBB = {}

function EmptyBB.centroid(_)
  error("EmptyBB has no centroid")
end
function EmptyBB.area(_)
  return 0
end
function EmptyBB.contains(_)
  return false
end
function EmptyBB.intersects(_)
  return false
end
function EmptyBB.enlarge_in_place(_)
  error("attempted to modify EmptyBB")
end
function EmptyBB.enlarge(_, other)
  return other:clone()
end
function EmptyBB.enlarged_area(_, other)
  return other:area()
end
function EmptyBB.intersect_area(_)
  return 0
end
function EmptyBB.intersect(_)
  return M.EMPTY
end
function EmptyBB.tostring()
  return "EmptyBB()"
end

setmetatable(EmptyBB, { __index = M })
local EmptyBB_meta = {
  __index = EmptyBB,
  __newindex = function() error("attempted to modify EmptyBB") end,
  __tostring = EmptyBB.tostring,
}
M.EMPTY = setmetatable({}, EmptyBB_meta)

local meta = {
  name = "BoundingBox",
  __index = M,
  __tostring = M.tostring,
}

local function new_from_factorio(bb)
  return M.new{bb.left_top.x, bb.right_bottom.x, bb.left_top.y, bb.right_bottom.y}
end

function M.new(coords)
  if coords.left_top then
    return new_from_factorio(coords)
  end

  if #coords % 2 ~= 0 then
    error("BoundingBox must have even number of coordinates for new")
  end

  for lower=1,#coords,2 do
    local upper = lower + 1
    if coords[lower] > coords[upper] then
      return M.EMPTY
    end
  end
  -- defensive copy
  local copy = {}
  for i=1,#coords do
    copy[i] = coords[i]
  end
  return setmetatable(copy, meta)
end

return M