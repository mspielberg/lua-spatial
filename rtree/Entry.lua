local BoundingBox = require "rtree.BoundingBox"

local M = {}

function M:tostring()
  return "Entry("..tostring(self.bounding_box)..")"
end

local meta = {
  name = "Entry",
  __index = M,
  __tostring = M.tostring,
}

function M.new(datum)
  local self = {
    bounding_box = BoundingBox.new(datum.bounding_box),
    datum = datum,
  }
  return setmetatable(self, meta)
end

return M