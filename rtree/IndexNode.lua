local Node = require "rtree.Node"

local M = {}
setmetatable(M, {__index = Node})

function M.new(children)
  local self = Node.new(children)
  return setmetatable(self, {__index = M, name="IndexNode"})
end

function M.is_leaf()
  return false
end

return M