local BoundingBox = require "rtree.BoundingBox"
local Node = require "rtree.Node"

local M = {}
setmetatable(M, {__index = Node})

local meta = {
  name = "LeafNode",
  __index = M,
  __tostring = M.tostring,
}

function M.new(children)
  local self = Node.new(children)
  return setmetatable(self, meta)
end

function M.is_leaf()
  return true
end

function M:insert(datum)
  if not next(self.children) then
    local bb = datum.bounding_box
    if bb.left_top then
      self.bounding_box = BoundingBox.new(
        bb.left_top.x,
        bb.left_top.y,
        bb.right_bottom.x,
        bb.right_bottom.y
      )
    else
      self.bounding_box = BoundingBox.new(table.unpack(bb))
    end
  end
  return Node.insert(self, datum)
end

function M:tostring()
  return "LeafNode("..tostring(self.bounding_box)..")"
end

return M