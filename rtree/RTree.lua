local Entry = require "rtree.Entry"
local IndexNode = require "rtree.IndexNode"
local LeafNode = require "rtree.LeafNode"

local NearestNeighbor = require "rtree.NearestNeighbor"

local serpent = require "serpent"

--[[
  tree = {
    dimension = ...,
    root = ...,
  }
]]
local M = {}

function M.new(dimension)
  local self = {
    dimension = dimension,
    root = LeafNode.new{},
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
  local path = {self.root}
  for level=1,desired_level do
    if path[level]:is_leaf() then
      return path
    end
    path[level+1] = choose_child(path[level], to_insert_bb)
  end
  return path
end

local insert

local function overflow_treatment(self, path, reinsert_levels)
  local level = #path
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
      if path[level-1]:insert(new_sibling) then
        path[level] = nil
        overflow_treatment(self, path, reinsert_levels)
      end
    end
  end
end

insert = function(self, node, reinsert_levels, desired_level)
  local path = choose_subtree(self, node.bounding_box, desired_level)
  local overfilled = path[#path]:insert(node)
  if overfilled then
    overflow_treatment(self, path, reinsert_levels)
  end
end

function M:insert(datum)
  local entry = Entry.new(datum)
  if #entry.bounding_box ~= self.dimension * 2 then
    error("entry with bounding box of "..#entry.bounding_box.." elements does not match dimension of "..self.dimension)
  end
  insert(self, entry, {}, math.huge)
end

local function find_leaf(node, entry, path)
  local children = node.children
  if node:is_leaf() then
    for i=1,#children do
      if children[i].datum == entry.datum then
        path[#path+1] = children[i]
        return path
      end
    end
  else
    for i=1,#children do
      local child = children[i]
      if child.bounding_box:contains(entry.bounding_box) then
        path[#path+1] = child
        if find_leaf(child, entry, path) then
          return path
        end
      end
    end
  end
  return nil
end

local function condense_tree(self, path)
  local to_reinsert = {}
  local to_remove = path[#path]
  for depth=#path-1,1,-1 do
    local node = path[depth]
    if to_remove then
      local underfilled = node:remove(to_remove)
      if underfilled then
        to_remove = node
        if depth > 1 then
          for i=1,#node.children do
            to_reinsert[#to_reinsert+1] = {node.children[i], depth+1}
          end
        end
      else
        to_remove = nil
      end
    else
      node:update_bounding_box()
    end
  end
  for i=1,#to_reinsert do
    insert(self, to_reinsert[i][1], {}, to_reinsert[i][2])
  end
end

function M:delete(datum)
  local path = find_leaf(self.root, Entry.new(datum), {self.root})
  if not path then
    return false
  end
  condense_tree(self, path)
  if not self.root:is_leaf() and #self.root.children == 1 then
    self.root = self.root.children[1]
  end
  return true
end

function M:nearest_neighbor(point)
  return NearestNeighbor.search(self.root, point)
end

return M