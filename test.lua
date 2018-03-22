serpent = require "serpent"
RTree = require "rtree.RTree"
data = {}
t = RTree.new()
function pp() print(serpent.block(t)) end
for i=1,5 do
  data[i] = {bounding_box={left_top={x=i,y=i},right_bottom={x=i+1,y=i+1}}}
  t:insert(data[i])
end
