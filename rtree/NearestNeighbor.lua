--[[
References:
  [RKV]:
    N. Roussopoulos, S. Kelley and F. Vincent,
    "Nearest Neighbor Queries",
    ACM SIGMOD, pages 71-79, 1995
]]

local serpent = require "serpent"

local M = {}

--[[
Guarantee: no object inside `bb` can be closer than sqrt(min_dist).
See Definition 2 of [RKV].
]]
local function min_dist(point, bb)
  local sum = 0
  for axis=1,#point do
    local coord = point[axis]
    local lower = bb[2*axis - 1]
    local upper = bb[2*axis]
    local d = 0
    if coord < lower then
      d = coord - lower
    elseif coord > upper then
      d = coord - upper
    end
    sum = sum + d * d
  end
  return sum
end

--[[
Guarantee: there is at least one object inside `bb` within sqrt(min_max_dist) of point.
See Definition 4 of [RKV].
On each axis, take nearest face, farthest point on that face.
Select nearest of these points, return distance to that point.
]]
local function min_max_dist(point, bb)
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

  local S = 0
  for axis=1,#point do
    local d = point[axis] - rM[axis]
    S = S + d * d
  end

  local min = math.huge
  for axis=1,#point do
    local d1 = point[axis] - rM[axis]
    local d2 = point[axis] - rm[axis]
    -- d = distance to point Vk
    local d = S - d1*d1 + d2*d2
    if d < min then
      min = d
    end
  end

  return min
end

local function point_metric(p1)
  return function(p2)
    local out = 0
    for i=1,#p1 do
      local d = p1[i] - p2[i]
      out = out + d * d
    end
    return out
  end
end

local function centroid_metric(point)
  local pm = point_metric(point)
  return function(entry)
    return pm(entry.bounding_box:centroid())
  end
end

local function nearest_entry(leaf, metric, nearest)
  local entries = leaf.children
  for i=1,#entries do
    local entry = entries[i]
    local d = metric(entry)
    if d < nearest[1] then
      nearest[1] = d
      nearest[2] = entry
    end
  end
end

local function active_branch_list(point, children)
  local out = {}
  for i=1,#children do
    local child = children[i]
    out[i] = {
      child,
      min_dist(point, child.bounding_box),
      min_max_dist(point, child.bounding_box),
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

local function up_prune(abl, nearest)
  for i=1,#abl do
    if abl[i][2] > nearest[1] then
      for j=i,#abl do
        abl[j] = nil
      end
      return
    end
  end
end

local function nearest_neighbor_search_core(node, point, metric, nearest)
  if node:is_leaf() then
    return nearest_entry(node, metric, nearest)
  end
  local abl = active_branch_list(point, node.children)
  down_prune(abl)
  for i=1,#abl do
    nearest_neighbor_search_core(abl[i][1], point, metric, nearest)
    up_prune(abl, nearest)
    if not abl[i+1] then
      break
    end
  end
  return nearest
end

function M.search(node, point)
  return nearest_neighbor_search_core(node, point, centroid_metric(point), {math.huge})[2]
end

return M