local BoundingBox = require "rtree.BoundingBox"

local serpent = require "serpent"

--[[
  {
    bounding_box = BoundingBox(...),
    children = {...},
    is_leaf = true,
  }
]]
local M = {}

local NUM_AXES = 2
local MIN_CHILDREN = 2
local MAX_CHILDREN = 4

local function group_bb(nodes, start, last)
  start = start or 1
  last = last or #nodes
  if start > last then
    return BoundingBox.EMPTY
  end
  local bb = nodes[start].bounding_box:clone()
  for i=start+1,last do
    bb:enlarge_in_place(nodes[i].bounding_box)
  end
  return bb
end

function M.new(children)
  local self = {
    children = children,
    bounding_box = group_bb(children),
  }
  return setmetatable(self, {__index = M})
end

local function axis_metric(axis)
  local lower = axis
  local upper = NUM_AXES + axis
  return function(a,b)
    local a_bb = a.bounding_box
    local b_bb = b.bounding_box
    return a_bb[lower] < b_bb[lower] or a_bb[upper] < b_bb[upper]
  end
end

local function sort_by_metric(children, metric)
  local sorted = {}
  for i=1,#children do
    sorted[i] = children[i]
  end
  table.sort(sorted, metric)
  return sorted
end

local function split_metrics(sorted)
  local margin_sum = 0
  local best_split_index
  local best_overlap = math.huge
  local best_area = math.huge
  local last = #sorted
  for split_index=MIN_CHILDREN,#sorted-MIN_CHILDREN do
    local g1_bb = group_bb(sorted, 1, split_index)
    local g2_bb = group_bb(sorted, split_index + 1, last)
    margin_sum = margin_sum + g1_bb:margin() + g2_bb:margin()
    local overlap =  g1_bb:intersect(g2_bb):area()
    local area = g1_bb:area() + g2_bb:area()
    if overlap < best_overlap or (overlap == best_overlap and area < best_area) then
      best_split_index = split_index
      best_overlap = overlap
      best_area = area
    end
  end
  return margin_sum, best_split_index
end

local function choose_split(self)
  local children = self.children
  local best_sorted
  local best_split_index
  local smallest_margin = math.huge
  for axis=1,NUM_AXES do
    local sorted = sort_by_metric(children, axis_metric(axis))
    local margin_sum, split_index = split_metrics(sorted)
    if margin_sum < smallest_margin then
      best_sorted = sorted
      best_split_index = split_index
      smallest_margin = margin_sum
    end
  end
  return best_sorted, best_split_index
end

function M:update_bounding_box()
  self.bounding_box = group_bb(self.children)
end

function M:split()
  local sorted, split_index = choose_split(self)
  local new_node_children = {}
  for i=1,#sorted-split_index do
    new_node_children[i] = sorted[i + split_index]
    sorted[i + split_index] = nil
  end
  local new_node = self.new(new_node_children)
  self.children = sorted
  self:update_bounding_box()
  self.bounding_box = group_bb(self.children)
  return new_node
end

-- returns true if self is now over capacity
function M:insert(child)
  local children = self.children
  children[#children+1] = child
  self.bounding_box:enlarge_in_place(child.bounding_box)
  return #children > MAX_CHILDREN
end

function M:remove(child)
  local children = self.children
  for i=1,#children do
    if children[i] == child then
      table.remove(self.children, i)
      self:update_bounding_box()
      return #children < MIN_CHILDREN
    end
  end
  error("remove called with non-child")
end

local function distance_2(p1, p2)
  local out = 0
  for i=1,NUM_AXES do
    local delta = p1[i] - p2[i]
    out = out + delta * delta
  end
  return out
end

function M:reinsert_candidate()
  local centroid = self.bounding_box:centroid()
  local most_distant
  local longest_distance_2 = 0
  for i=1,#self.children do
    local child = self.children[i]
    local child_distance_2 = distance_2(centroid, child.bounding_box:centroid())
    if child_distance_2 > longest_distance_2 then
      most_distant = child
      longest_distance_2 = child_distance_2
    end
  end
  return most_distant
end

return M