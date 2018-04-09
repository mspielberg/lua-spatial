-- various distance metrics for two points
local M = {}

function M.abs_vector_iter(p1, p2)
  local i = 1
  return function()
    if i > #p1 then
      return nil
    end
    local out = math.abs(p1[i] - p2[i])
    i = i + 1
    return out
  end
end

function M.abs_vector(p1, p2)
  local out = {}
  for i=1,#p1 do
    out[i] = math.abs(p1[i] - p2[i])
  end
  return out
end

function M.manhattan(p1, p2)
  local d = 0
  for i=1,#p1 do
    d = d + math.abs(p1[i] - p2[i])
  end
  return d
end

function M.euclidean2(p1, p2)
  local d2 = 0
  for i=1,#p1 do
    local delta = p1[i] - p2[i]
    d2 = d2 + (delta * delta)
  end
  return d2
end

function M.euclidean(p1, p2)
  return M.euclidean2(p1, p2) ^ 0.5
end

function M.minkowski(p)
  if p == 1 then
    return M.manhattan
  elseif p == 2 then
    return M.euclidean
  end

  local function delta(p1, p2, d)
    return math.abs(p1[d] - p2[d])
  end
  local function comp(p1, p2, d)
    return delta(p1, p2, d) ^ p
  end
  local function p_norm_p(p1, p2)
    local s = 0
    for d=1,#p1 do
      s = s + comp(p1, p2, d)
    end
    return s
  end
  return function(p1, p2)
    return p_norm_p(p1, p2) ^ (1/p)
  end
end

function M.chebyshev(p1, p2)
  local d = 0
  for i=1,#p1 do
    local comp = math.abs(p1[i] - p2[i])
    if comp > d then
      d = comp
    end
  end
  return d
end
M.chessboard = M.chebyshev

return M