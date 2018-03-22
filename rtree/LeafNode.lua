local BoundingBox = require "rtree.BoundingBox"
local Node = require "rtree.Node"

local M = {}
setmetatable(M, {__index = Node})

function M.is_leaf()
  return true
end

function M:insert(entry)
  if self.bounding_box == BoundingBox.EMPTY then
    self.bounding_box = entry.bounding_box:clone()
  end
  return Node.insert(self, entry)
end

function M:tostring()
  local s = "Leaf("..tostring(self.bounding_box)..":"
  for i=1,#self.children-1 do
    s = s..tostring(self.children[i].bounding_box)..","
  end
  return s..tostring(self.children[#self.children].bounding_box)..")"
end

local meta = {
  name = "LeafNode",
  __index = M,
  __tostring = M.tostring,
}

function M.new(children)
  local self = Node.new(children)
  self.height = 0
  return setmetatable(self, meta)
end

return M