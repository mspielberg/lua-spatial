local heap = require "rtree.heap"

-- KNearest tracks up to K values with the smallest keys.
local M = {}

-- comparison for a max-heap by mindist metric
local function maxheap_comparison(a, b)
  return a > b
end

function M.new(K)
  local self = {
    heap:new(maxheap_comparison),
    K,
  }
  return setmetatable(self, {__index = M})
end

-- peek returns the largest key currently tracked and its corresponding value.
function M:peek()
  local entry = self[1][1]
  return entry.key, entry.value
end

-- insert starts tracking v with key k.
-- If there are already K tracked items, the item with the largest key is removed.
function M:insert(k, v)
  if self[1].length < self[2] then
    self[1]:insert(k, v)
    return
  end
  if k < self[1][1].key then
    self[1]:pop()
    self[1]:insert(k, v)
  end
end

-- to_table returns an array with the tracked items in descending key order.
-- All items are removed after to_table returns.
function M:to_table()
  local out = {}
  for i=self[1].length,1,-1 do
    local _
    _, out[i] = self[1]:pop()
  end
  return out
end

return M