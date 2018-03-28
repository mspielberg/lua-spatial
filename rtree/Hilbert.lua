-- derived from C code at https://en.wikipedia.org/wiki/Hilbert_curve

local M = {}

-- Factorio coordinates range from [-1e6, 1e6] at a grid granulatity of 0.5,
-- so we use a (discrete) Hilbert curve over a square of side length 4Mi (2^22)
local N = 2 ^ 22
local MAX_COORD = N - 1
local OFFSET = N / 2

local function rot(x, y, rx, ry)
  if not ry then
    if rx then
      x = MAX_COORD - x
      y = MAX_COORD - y
    end
    return y,x
  end
  return x,y
end

-- workaround for lack of bitwise-and for integers larger than 32 bits
-- s must be a power of 2
local function is_bit_set(x, s)
  -- mask off all bits to the left of s
  x = x % (s * 2)
  -- mask off all bits to the right of s
  x = x - (x % s)
  return x == s
end

function M.xy2d(x, y)
  x = x * 2 + OFFSET
  y = y * 2 + OFFSET

  local d = 0
  local s = N / 2
  while s >= 1 do
    local rx = is_bit_set(x, s)
    local ry = is_bit_set(y, s)
    -- factor = ((3 * rx) XOR ry)
    local factor = rx and (ry and 2 or 3) or (ry and 1 or 0)
    d = d + s * s * factor
    x, y = rot(x, y, rx, ry)
    s = s / 2
  end
  return d
end

return M
