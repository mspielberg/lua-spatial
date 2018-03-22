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

function M:insert(entry)
  if self.bounding_box == BoundingBox.EMPTY then
    self.bounding_box = entry.bounding_box:clone()
  end
  return Node.insert(self, entry)
end

function M:tostring()
  return "LeafNode("..tostring(self.bounding_box)..")"
end

return M