local BoundingBox = require "rtree.BoundingBox"
--local serpent = require "serpent"

--[[
  {
    bounding_box = BoundingBox(...),
    children = {...},
  }
]]
local M = {}

local MIN_CHILDREN = 2
local MAX_CHILDREN = 4

-- set_mbr sets bb to be the minimum bounding rectangle of nodes[start..last]
local function set_mbr(bb, nodes, start, last)
  start = start or 1
  last = last or #nodes
  if start > last then
    return BoundingBox.EMPTY
  end
  local start_bb = nodes[start].bounding_box
  for i=1,#start_bb do
    bb[i] = start_bb[i]
  end
  for i=start+1,last do
    bb:enlarge_in_place(nodes[i].bounding_box)
  end
end

function M:is_leaf()
  return self.height == 0
end

local function axis_metric(axis)
  local lower = axis
  local upper = axis + 1
  return function(a,b)
    local a_bb = a.bounding_box
    local b_bb = b.bounding_box
    local a_l = a_bb[lower]
    local a_u = a_bb[upper]
    local b_l = b_bb[lower]
    local b_u = b_bb[upper]
    return a_l < b_l or (a_l == b_l and a_u < b_u)
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

-- reused and overwritten during split_metrics
local g1_bb = BoundingBox.new{}
local g2_bb = BoundingBox.new{}
local function split_metrics(sorted)
  local margin_sum = 0
  local best_split_index
  local best_overlap = math.huge
  local best_area = math.huge
  local last = #sorted
  for split_index=MIN_CHILDREN,#sorted-MIN_CHILDREN do
    set_mbr(g1_bb, sorted, 1, split_index)
    set_mbr(g2_bb, sorted, split_index + 1, last)
    margin_sum = margin_sum + g1_bb:margin() + g2_bb:margin()
    local overlap = g1_bb:intersect_area(g2_bb)
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
  for axis=1,#self.bounding_box/2 do
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
  if not next(self.children) then
    self.bounding_box = BoundingBox.EMPTY
  elseif self.bounding_box == BoundingBox.EMPTY then
    self.bounding_box = BoundingBox.new{}
  end
  set_mbr(self.bounding_box, self.children)
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
  return new_node
end

-- returns true if self is now over capacity
function M:insert(child)
  local children = self.children
  children[#children+1] = child
  if self.bounding_box == BoundingBox.EMPTY then
    self.bounding_box = child.bounding_box:clone()
  else
    self.bounding_box:enlarge_in_place(child.bounding_box)
  end
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
  for i=1,#p1 do
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

function M:tostring()
  local s = "Node("..tostring(self.bounding_box)..":"
  if self.height == 0 then
    for i=1,#self.children-1 do
      s = s..tostring(self.children[i].bounding_box)..","
    end
    if next(self.children) then
      s = s..tostring(self.children[#self.children].bounding_box)
    end
  else
    for i=1,#self.children-1 do
      s = s..tostring(self.children[i])..","
    end
    if next(self.children) then
      s = s..tostring(self.children[#self.children])
    end
  end
  return s..")"
end

local meta = {
  __index = M,
  --__tostring = M.tostring,
}

function M.new(children)
  local self = {
    bounding_box = BoundingBox.EMPTY,
    children = children,
    height = children[1] and children[1].height and (children[1].height + 1) or 0,
  }
  setmetatable(self, meta)
  self:update_bounding_box()
  return self
end

return M