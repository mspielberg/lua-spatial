local util = require "grid.util"

describe("Grid util", function()
  describe("should calculate distance from chunk boundary", function()
    it("handles near lower boundary", function()
      assert.are.equal(2, util.distance_to_chunk_boundary(32, 2, 2))
      assert.are.equal(2, util.distance_to_chunk_boundary(32, 2, 6))
      assert.are.equal(0, util.distance_to_chunk_boundary(32, 64, 2))
      assert.are.equal(0, util.distance_to_chunk_boundary(32, 64, 6))
    end)

    it("handles near upper boundary", function()
      assert.are.equal(1, util.distance_to_chunk_boundary(32, 31, 1))
      assert.are.equal(1, util.distance_to_chunk_boundary(32, 31, 6))
      assert.are.equal(1, util.distance_to_chunk_boundary(32, -33, 1))
      assert.are.equal(1, util.distance_to_chunk_boundary(32, -33, 6))
    end)
  end)

  describe("should iterate chunks in increasing radius", function()
    it("yields expected chunk coordinates give a starting chunk and radius", function()
      local cx,cy = 5,50
      local expected_by_radius = {
        [0] = {
          {5,50},
        },
        [1] = {
          {4,49}, {5,49}, {6,49},
          {4,50},         {6,50},
          {4,51}, {5,51}, {6,51},
        },
        [2] = {
          {3,48}, {4,48}, {5,48}, {6,48}, {7,48},
          {3,49},                         {7,49},
          {3,50},                         {7,50},
          {3,51},                         {7,51},
          {3,52}, {4,52}, {5,52}, {6,52}, {7,52},
        },
      }
      for r, expected in ipairs(expected_by_radius) do
        local actual = {}
        for x,y in util.radius_iter(cx, cy, r) do
          actual[#actual+1] = {x,y}
        end
        assert.are.same(expected, actual)
      end
    end)
  end)
end)