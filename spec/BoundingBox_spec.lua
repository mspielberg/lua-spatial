local BoundingBox = require "rtree.BoundingBox"
describe("BoundingBox", function()
  describe("should allow creation from coordinates", function()
    it("should support Factorio-style bounding boxes", function()
      assert.are.same(BoundingBox.new{1,3,1,3}, BoundingBox.new{left_top = {x=1,y=1}, right_bottom={x=3,y=3}})
    end)

    it("should support degenerate intervals", function()
      assert.are_not.equal(BoundingBox.new{0,0}, BoundingBox.EMPTY)
    end)

    it("should result in EMPTY when fed empty intervals", function()
      assert.are.equal(BoundingBox.new{1,0}, BoundingBox.EMPTY)
      assert.are.equal(BoundingBox.new{1,2,3,2.9999999}, BoundingBox.EMPTY)
    end)

    it("should error with incorrect number of arguments", function()
      assert.has_error(function() BoundingBox.new{0} end)
      assert.has_error(function() BoundingBox.new{1,2,3} end)
    end)
  end)

  describe("should support combinations with EMPTY", function()
    local bb = BoundingBox.new{1,1,2,2}

    it("should return a copy of the original from enlarge with EMPTY", function()
      assert.are_not.equal(bb, bb:enlarge(BoundingBox.EMPTY))
      assert.are_not.equal(bb, BoundingBox.EMPTY:enlarge(bb))
      assert.are.same(bb, bb:enlarge(BoundingBox.EMPTY))
      assert.are.same(bb, BoundingBox.EMPTY:enlarge(bb))
    end)

    it("should return EMPTY from intersect with EMPTY", function()
      assert.are.same(BoundingBox.EMPTY, bb:intersect(BoundingBox.EMPTY))
      assert.are.same(BoundingBox.EMPTY, BoundingBox.EMPTY:intersect(bb))
    end)

    it("should return false for intersects with EMPTY", function()
      assert.is_false(BoundingBox.EMPTY:intersects(BoundingBox.EMPTY))
      assert.is_false(BoundingBox.EMPTY:intersects(bb))
      assert.is_false(bb:intersects(BoundingBox.EMPTY))
    end)

    it("should error when attempting to modify EMPTY", function()
      assert.has_error(function() BoundingBox.EMPTY[1] = 0 end)
      assert.has_error(function() BoundingBox.EMPTY:enlarge_in_place(bb) end)
    end)
  end)

  describe("should support geometric property accessors", function()
    it("should support centroid", function()
      assert.are.same({2,2}, BoundingBox.new{1,3,1,3}:centroid())
      assert.are.same({1.5,2}, BoundingBox.new{1,2,1,3}:centroid())
      assert.are.has_error(function() BoundingBox.EMPTY:centroid() end)
    end)

    it("should support area", function()
      assert.are.equal(4, BoundingBox.new{1,3,1,3}:area())
      assert.are.equal(2, BoundingBox.new{1,2,1,3}:area())
      assert.are.equal(0, BoundingBox.EMPTY:area())
    end)

    it("should support margin (perimeter)", function()
      assert.are.equal(8, BoundingBox.new{1,3,1,3}:margin())
      assert.are.equal(6, BoundingBox.new{1,2,1,3}:margin())
      assert.are.equal(0, BoundingBox.EMPTY:margin())
    end)
  end)

  describe("should support in-place modification", function()
    local bb = BoundingBox.new{1,3,1,3}
    it("should support modification of coordinates", function()
      assert.has_no.errors(function() bb[1] = 2 end)
      assert.are.same(2, bb:area())
    end)
  end)

  describe("should support geometric predicates", function()
    local bb1 = BoundingBox.new{1,2,1,2}
    local bb2 = BoundingBox.new{3,4,3,4}
    local bb3 = BoundingBox.new{2,2.5,2,2.5}
    local bb4 = BoundingBox.new{1,3,1,3}

    it("should support contains", function()
      assert.is_false(bb1:contains(bb2))
      assert.is_false(bb2:contains(bb1))
      assert.is_true(bb4:contains(bb1))
      assert.is_false(bb1:contains(bb4))
      assert.is_false(bb4:contains(bb2))

      assert.is_true(bb1:contains(bb1))
      assert.is_true(bb2:contains(bb2))
      assert.is_true(bb3:contains(bb3))
      assert.is_true(bb4:contains(bb4))

      assert.is_false(bb1:contains(BoundingBox.EMPTY))
      assert.is_false(BoundingBox.EMPTY:contains(bb1))
    end)

    it("should support intersects", function()
      assert.is_false(bb1:intersects(bb2))
      assert.is_false(bb2:intersects(bb1))
      assert.is_true(bb1:intersects(bb3))
      assert.is_true(bb3:intersects(bb1))
    end)
  end)

  describe("should support combining boxes", function()
    local bb1 = BoundingBox.new{1,3,1,3}
    local bb2 = BoundingBox.new{2,4,2,4}
    local bb12 = BoundingBox.new{1,4,1,4}
    local bb1_2 = BoundingBox.new{2,3,2,3}

    it("should support enlargement", function()
      assert.are.same(bb12, bb1:enlarge(bb2))
      assert.are_not.equal(bb12, bb1:enlarge(bb2))
      assert.are.same(bb12, bb2:enlarge(bb1))
      assert.are_not.equal(bb12, bb2:enlarge(bb1))
    end)

    it("should support enlargement in-place", function()
      local copy = bb1:clone()
      assert.are_not.equal(copy, bb1)
      copy:enlarge_in_place(bb2)
      assert.are.same(bb12, copy)
    end)

    it("should support intersect", function()
      assert.are.same(bb1_2, bb1:intersect(bb2))
      assert.are.same(bb1_2, bb2:intersect(bb1))
    end)
  end)

  describe("should support pretty-printing", function()
    it("should render EMPTY", function()
      assert.are.equal("EmptyBB()", tostring(BoundingBox.EMPTY))
    end)

    it("should render non-empty", function()
      assert.are.equal("BB(1,1;3,3)", tostring(BoundingBox.new{1,3,1,3}))
    end)
  end)
end)