local BoundingBox = require "rtree.BoundingBox"

local M = {}

local meta = {
  name = "Entry",
  __index = M,
}

function M.new(datum)
  local self = {
    bounding_box = BoundingBox.new(datum.bounding_box),
    datum = datum,
  }
  return setmetatable(self, meta)
end

return M