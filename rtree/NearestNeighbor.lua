--[[
References:
  [RKV]:
    N. Roussopoulos, S. Kelley and F. Vincent,
    "Nearest Neighbor Queries",
    ACM SIGMOD, pages 71-79, 1995
]]

local KNearest = require "rtree.KNearest"
local Metrics = require "rtree.Metrics"

local M = {}

--[[
Guarantee: no object inside `bb` can be closer than min_dist.
See Definition 2 of [RKV].
]]
local function min_dist(point, bb, metric)
  -- nearest point in bb to point, considering only specified axis
  local function nearest_on_axis(axis)
      local coord = point[axis]
      local lower = bb[2*axis - 1]
      local upper = bb[2*axis]
      if coord < lower then
        return coord - lower
      elseif coord > upper then
        return coord - upper
      end
      return coord
  end

  local nearest_point = {}
  for axis=1,#point do
    nearest_point[axis] = nearest_on_axis(point, bb, axis)
  end
  return metric(point, nearest_point)
end

--[[
Guarantee: there is at least one object inside `bb` within min_max_dist of point.
See Definition 4 of [RKV].
On each axis, take nearest face, farthest point on that face.
Select nearest of these points, return distance to that point.
]]
local function min_max_dist(point, bb, metric)
  local centroid = bb:centroid()

  -- rm[k] = nearer bb edge coordinate on axis k
  local rm = {}
  -- rM[k] = farther bb edge coordinate on axis k
  local rM = {}

  for axis=1,#point do
    local lower = bb[2*axis - 1]
    local upper = bb[2*axis]
    if point[axis] <= centroid[axis] then
      rm[axis] = lower
      rM[axis] = upper
    else
      rm[axis] = upper
      rM[axis] = lower
    end
  end

  --[[
  Given axis k, take nearest face. Farthest point on that face is:
  Vk = (rM[1], rM[2], rM[3], ... rm[k], rM[k+1], rM[k+2], ...)
  i.e., take farther edge coordinate in all axes except k.
  ]]
  local function Vk(k)
    local out = {}
    for i=1,#rm do
      out[i] = (i == k) and rm[i] or rM[i]
    end
    return out
  end

  -- choose axis that gives minimum Vk ("min" of max_dist)
  local min = math.huge
  for axis=1,#point do
    local d = metric(point, Vk(axis))
    if d < min then
      min = d
    end
  end

  return min
end

local function nearest_entry(leaf, point, metric, knearest)
  local entries = leaf.children
  for i=1,#entries do
    local entry = entries[i]
    local d = metric(point, entry:centroid())
    knearest:insert(d, entry)
  end
end

local function active_branch_list(point, children, metric)
  local out = {}
  for i=1,#children do
    local child = children[i]
    out[i] = {
      child,
      min_dist(point, child.bounding_box, metric),
      min_max_dist(point, child.bounding_box, metric),
    }
  end
  -- sort by min_dist
  table.sort(out, function(a,b) return a[2] < b[2] end)
  return out
end

local function down_prune(abl)
  local smallest_minmaxdist = abl[1][3]
  for i=2,#abl do
    local minmaxdist = abl[i][3]
    if minmaxdist < smallest_minmaxdist then
      smallest_minmaxdist = minmaxdist
    end
  end

  for i=1,#abl do
    if abl[i][2] > smallest_minmaxdist then
      for j=i,#abl do
        abl[j] = nil
      end
      return
    end
  end
end

local function up_prune(abl, knearest)
  for i=1,#abl do
    if abl[i][2] > knearest:peek() then
      for j=i,#abl do
        abl[j] = nil
      end
      return
    end
  end
end

local function nearest_neighbor_search_core(node, point, metric, knearest)
  if node:is_leaf() then
    return nearest_entry(node, metric, knearest)
  end
  local abl = active_branch_list(point, node.children, metric)
  down_prune(abl)
  for i=1,#abl do
    nearest_neighbor_search_core(abl[i][1], point, metric, knearest)
    up_prune(abl, knearest)
    if not abl[i+1] then
      break
    end
  end
end

function M.search(node, point, k, metric)
  local knearest = KNearest.new(k or 1)
  nearest_neighbor_search_core(node, point, metric, knearest)
  return knearest:to_table()
end

return M