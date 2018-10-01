Grid=require 'grid.Grid'
g = Grid.new()
data = {}
for i=1,5 do
  data[i] = {
    position = {x=i+0.5,y=i+0.5},
    bounding_box={left_top={x=i,y=i},right_bottom={x=i+1,y=i+1}},
  }
  g:insert(data[i])
end