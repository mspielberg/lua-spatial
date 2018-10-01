local Grid = require "grid.Grid"
local Metrics = require "rtree.Metrics"
local RTree = require "rtree.RTree"
local serpent = require "serpent"

local NUM_CLUSTERS = 10

local function create_clusters(index)
  local start = os.clock()
  for i=1,NUM_CLUSTERS do
    -- create cluster
    local x, y = math.random(1000), math.random(1000)
    for xx = x*100,x*100+50 do
      for yy = y*100,y*100+50 do
        local entity = {
          unit_number = i*1000 + xx*100 + yy,
          position = {x = xx + 0.5, y = yy + 0.5},
          bounding_box = {
            left_top = {x = xx, y = yy},
            right_bottom = {x = xx + 1, y = yy + 1},
          },
        }
        index:insert(entity)
      end
    end
    print("created cluster at "..(x*100)..", "..(y*100))
  end
  local elapsed = os.clock() - start
  print("created clusters in "..elapsed)
end

local function search(index)
  local found = 0
  local start = os.clock()
  for x = 0,100000,100 do
    for y = 0,100000,100 do
      local results = index:search{
        left_top = {x-50,y-50},
        right_bottom = {x+50, y+50},
      }
      if #results > 0 then
        print("found "..#results.." at "..x..", "..y)
      found = found + #results
      end
    end
  end
  local elapsed = os.clock() - start
  print("found "..found.." in "..elapsed.." "..(elapsed/500/500).. "per search")
end

local g = Grid.new()
create_clusters(g)
search(g)
do return end

--[[
local total = 0
for x, row in pairs(g[2]) do
  for y, col in pairs(row) do
    local cnt = 0
    for _ in pairs(col) do
      cnt = cnt + 1
    end
    total = total + cnt
    print(cnt .." entities in chunk "..x..","..y)
  end
end
print(total .. " entities in total")
]]

local rt = RTree.new()
create_clusters(rt)
search(rt)