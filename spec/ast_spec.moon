import Atom, Xpr from require 'ast'

describe 'Atom', ->
  expand = (typ, str, ...) ->
    atom = Atom["make_#{typ}"] str
    atom\expand ...
    atom.value\getc!

  describe 'sym', ->
    it 'expand correctly', ->
      env = { a: 1, b: 2, c: 44, 'long_name': 'str',
              'name/with/slash': {} }

      for k,v in pairs env
        assert.is.equal v, expand 'sym', k, env

  describe 'num', ->
    it 'expand correctly', ->
      assert.is.equal 1,    expand 'num', '1'
      assert.is.equal 0,    expand 'num', '0'
      assert.is.equal .1,   expand 'num', '.1'
      assert.is.equal .123, expand 'num', '.123'
      assert.is.equal 20,   expand 'num', '20'
      assert.is.equal 20,   expand 'num', '20.'
      assert.is.equal 20.1, expand 'num', '20.1'

  describe 'strd', ->
    it 'expand correctly', ->
      assert.is.equal 'hello',       expand 'strd', 'hello'
      assert.is.equal 'hello world', expand 'strd', 'hello world'
      assert.is.equal '',            expand 'strd', ''
      assert.is.equal '\\',          expand 'strd', '\\\\'
      assert.is.equal "'",           expand 'strd', "\\'"
      assert.is.equal '"',           expand 'strd', '\\"'
      assert.is.equal "a string with ' inside",
                      expand 'strd', "a string with ' inside"

  describe 'strq', ->
    it 'expand correctly', ->
      assert.is.equal 'hello',       expand 'strq', 'hello'
      assert.is.equal 'hello world', expand 'strq', 'hello world'
      assert.is.equal '',            expand 'strq', ''
      assert.is.equal '\\',          expand 'strq', '\\\\'
      assert.is.equal "'",           expand 'strq', "\\'"
      assert.is.equal '"',           expand 'strq', '\\"'
      assert.is.equal 'a string with " inside',
                      expand 'strq', 'a string with " inside'

describe 'Xpr', ->
  describe 'can be tagged', ->
    xpr = Xpr.make_sexpr 2, {''}
    assert.is.equal 2, xpr.tag
    assert.is.equal '([2])', xpr\stringify!

  describe 'can be walked', ->
    a1 = Atom.make_num '1'
    a2 = Atom.make_num '2'
    a3 = Atom.make_num '3'
    x1   = Xpr.make_sexpr { '', a1, '' }
    x21  = Xpr.make_sexpr { '', a2, '' }
    x22  = Xpr.make_sexpr { '', a3, '' }
    x2   = Xpr.make_sexpr { '', x21, ' ', x22, '' }
    root = Xpr.make_nexpr { '', x1, ' ', x2, '' }

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
