local BoundingBox = require "rtree.BoundingBox"

local M = {}

local meta = {
  name = "Entry",
  __index = M,
}

function M.new(datum)
  local bb = datum.bounding_box
  if bb.left_top then
    bb = BoundingBox.new{bb.left_top.x, bb.right_bottom.x, bb.left_top.y, bb.right_bottom.y}
  else
    bb = BoundingBox.new(bb)
  end
  local self = {
    bounding_box = bb,
    datum = datum,
  }
  return setmetatable(self, meta)
end

return M