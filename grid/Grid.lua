local util = require "grid.util"

local M = {}

local function chunk(self, cx, cy, create)
  local row = self[2][cx]
  if not row then
    if not create then
      return nil
    end
    row = {}
    self[2][cx] = row
  end
  local col = row[cy]
  if not col then
    if not create then
      return nil
    end
    col = {}
    row[cy] = col
  end
  return col
end

function M:insert(entity)
  local p = entity.position
  local cx, cy = util.chunkxy(self[1], p)
  local c = chunk(self, cx, cy, true)
  c[entity.unit_number] = {
    entity = entity,
    position = entity.position,
    bounding_box = entity.bounding_box,
    distance = nil, -- distance used in nearest_neighbors
  }
end

function M:delete(entity)
  local p = entity.position
  local cx, cy = util.chunkxy(self[1], p)
  local c = chunk(self, cx, cy)
  if not c then
    return false
  end
  if c[entity.unit_number] then
    c[entity.unit_number] = nil
    if not next(c) then
      self[2][cx][cy] = nil
      if not next(self[2][cx]) then
        self[2][cx] = nil
      end
    end
    return true
  end
  return false
end

local function intersects(a1, a2)
  return not(a1.left_top.x > a2.right_bottom.x
    or a1.left_top.y > a2.right_bottom.y
    or a1.right_bottom.x < a2.left_top.x
    or a1.right_bottom.y < a2.left_top.y)
end

function M:search(area)
  area = util.normalize_bounding_box(area)
  local res = self[1]
  local cx1, cy1 = util.chunkxy(res, area.left_top)
  local cx2, cy2 = util.chunkxy(res, area.right_bottom)
  local out = {}
  for cx=cx1,cx2+1 do
    for cy=cy1,cy2+1 do
      local c = chunk(self, cx, cy)
      if c then
        for _, entry in pairs(c) do
          if intersects(area, entry.bounding_box) then
            out[#out+1] = entry.entity
          end
        end
      end
    end
  end
  return out
end

local function distance(p1, p2)
  return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

local function ascending_by_distance(a, b)
  return a.distance < b.distance
end

local function extract_entities(entries)
  for i=1,#entries do
    entries[i] = entries[i].entity
  end
  return entries
end

function M:nearest_neighbors(position, k, max_distance)
  position = util.normalize_position(position)
  local res = self[1]
  local from_boundary = util.distance_to_chunk_boundary(res, position.x, position.y)
  local pcx, pcy = util.chunkxy(res, position)
  local candidates = {}
  local max_chunk_radius = max_distance <= from_boundary and 0 or math.ceil(max_distance / res)
  for cr=0,max_chunk_radius do
    for cx, cy in util.chunk_radius_iter(self, pcx, pcy, cr) do
      local c = chunk(self, cx, cy)
      if c then
        for _, entry in pairs(c) do
          local d = distance(position, entry.position)
          if d <= max_distance then
            entry.distance = d
            candidates[#candidates+1] = entry
          end
        end
      end
    end
    if #candidates >= k then
      table.sort(candidates, ascending_by_distance)
      for i=k+1,#candidates do
        candidates[i] = nil
      end
      break
    end
  end
  return extract_entities(candidates)
end

local meta = {
  __index = M,
}

function M.new(resolution)
  resolution = resolution or 32
  local self = {
    resolution,
    {},
  }
  return setmetatable(self, meta)
end

return M