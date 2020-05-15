import do_setup from require 'spec.test_setup'
import Cell, RootCell from require 'alv.cell'
import Constant, Scope, Tag, SimpleRegistry, globals from require 'alv'

setup do_setup

hello_world = Cell.parse Tag.parse('2'), {
  '', (Constant.sym 'hello'), ' ', (Constant.str 'world'), ''
}
two_plus_two = Cell.parse Tag.parse('3'), {
  '', (Constant.sym '+'), ' ', (Constant.num 2), ' ', (Constant.num 2), ''
}

describe 'Cell', ->
  describe 'when cloned', ->
    parent = Tag.blank '1'
    with hello_world\clone parent
      it 'keeps children', ->
        assert.is.equal Cell, .__class
        assert.is.equal (Constant.sym 'hello'), \head!
        assert.is.same { Constant.str 'world' }, \tail!

      it 'clones the tag', ->
        assert.is.equal hello_world.tag, .tag.original
        assert.is.equal parent, .tag.parent

  describe 'when evaluated', ->
    it 'errors when empty', ->
      cell = Cell.parse {''}
      assert.has.error -> cell\eval globals

    it 'evaluates its head', ->
      head = Constant.sym 'trace'
      cell = Cell.parse { '', head, ' ', (Constant.sym 'true'), '' }

      s = spy.on head, 'eval'
      cell\eval globals
      assert.spy(s).was_called_with (match.is_ref head), (match.is_ref globals)

describe 'RootCell', ->
  test 'tag is always [0]', ->
    cell = Cell.parse_root {}
    assert.is.equal '[0]', cell.tag\stringify!

  test 'head is always "do"', ->
    cell = Cell.parse_root {}
    assert.is.equal (Constant.sym 'do'), cell\head!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.equal (Constant.sym 'do'), cell\head!

  test 'tail is all children', ->
    cell = Cell.parse_root {}
    assert.is.same {}, cell\tail!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.same { hello_world, two_plus_two },
                   cell\tail!
