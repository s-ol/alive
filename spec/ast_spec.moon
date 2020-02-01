import Atom, Xpr from require 'ast'

describe 'AST', ->
  describe 'can be walked', ->
    a1 = Atom '1', '', 1
    a2 = Atom '2', '', 2
    a3 = Atom '3', '', 3
    x1 = Xpr { '', a1, '' }
    x21 = Xpr { '', a2, '' }
    x22 = Xpr { '', a3, '' }
    x2 = Xpr { '', x21, ' ', x22, '' }

    root = Xpr { '', x1, ' ', x2, '' }, 'naked'

    assert_yields = (expected_order, iter) ->
      for val in *expected_order
        got_typ, got_val = iter!
        assert.is.equal val.type, got_typ
        assert.is.equal val, got_val
      assert.is.nil iter!

    it 'inside-out', ->
      assert_yields { a1, x1, a2, x21, a3, x22, x2, root }, root\walk 'inout'

    it 'inside-out, skipping the root', ->
      assert_yields { a1, x1, a2, x21, a3, x22, x2 }, root\walk 'inout', false

    it 'outside-in', ->
      assert_yields { root, x1, a1, x2, x21, a2, x22, a3 }, root\walk 'outin'

    it 'outside-in, skipping the root', ->
      assert_yields { x1, a1, x2, x21, a2, x22, a3 }, root\walk 'outin', false

    it 'errors when direction is wrong or absent', ->
      assert.has.errors -> root\walk!
      assert.has.errors -> root\walk 'backandforth'
