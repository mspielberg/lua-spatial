local Node = require "rtree.Node"
local serpent = require "serpent"

local M = {}
setmetatable(M, {__index = Node})

function M.is_leaf()
  return false
end

function M:tostring()
  local s = "Index("..tostring(self.bounding_box)..":"
  for i=1,#self.children-1 do
    s = s..tostring(self.children[i])..","
  end
  return s..tostring(self.children[#self.children])..")"
end

local meta = {
  __index = M,
  --__tostring = M.tostring,
}

function M.new(children)
  local self = Node.new(children)
  local child_height = children[1].height
  for i=2,#children do
    if children[i].height ~= child_height then
      print("height inconsistency: "..serpent.block(children))
    end
  end
  self.height = child_height + 1
  return setmetatable(self, meta)
end

return M