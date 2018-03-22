local IndexNode = require "rtree.IndexNode"
local LeafNode = require "rtree.LeafNode"

local serpent = require "serpent"

--[[
  tree = {
    root = ...,
  }
]]
local M = {}

function M.new()
  local self = {
    root = LeafNode.new{}
  }
  return setmetatable(self, {__index = M})
end

-- find next node by Guttman's minimum area enlargement criterion
local function choose_child(node, to_insert_bb)
  local children = node.children
  local candidate_child
  local smallest_enlargement = math.huge
  local smallest_area = math.huge
  for i=1,#children do
    local child = children[i]
    local child_bb = child.bounding_box
    local child_area = child_bb:area()
    local enlargement = child_bb:enlarge(to_insert_bb):area() - child_bb:area()
    if enlargement < smallest_enlargement or (enlargement == smallest_enlargement and child_area < smallest_area) then
      candidate_child = child
      smallest_enlargement = enlargement
      smallest_area = child_area
    end
  end
  return candidate_child
end

local function choose_subtree(self, to_insert_bb, desired_level)
  if not to_insert_bb then error("to_insert_bb") end
  desired_level = desired_level or math.huge
  local path = {self.root}
  local level = 1
  local node = self.root
  while not node:is_leaf() and level < desired_level do
    node = choose_child(node, to_insert_bb)
    level = level + 1
    path[level] = node
  end
  return path, level
end

local insert

local function overflow_treatment(self, path, level, reinsert_levels)
  local node = path[level]
  if not reinsert_levels[level] then
    reinsert_levels[level] = true
    local to_reinsert = node:reinsert_candidate()
    node:remove(to_reinsert)
    insert(self, to_reinsert, reinsert_levels, level)
  else
    local new_sibling = node:split()
    if level == 1 then
      -- need a new root
      self.root = IndexNode.new({node, new_sibling})
    else
      local parent = path[level-1]
      if parent:insert(new_sibling) then
        overflow_treatment(self, path, level-1, reinsert_levels)
      end
    end
  end
end

insert = function(self, node, reinsert_levels, desired_level)
  local path, level = choose_subtree(self, node.bounding_box, desired_level)
  local overfilled = path[level]:insert(node)
  if overfilled then
    overflow_treatment(self, path, level, reinsert_levels)
  end
end

function M:insert(datum)
  insert(self, datum, {}, nil)
end

return M