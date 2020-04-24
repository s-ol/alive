import Cell, RootCell from require 'alv.cell'
import ValueStream, Scope, Tag, SimpleRegistry, globals from require 'alv'
import Logger from require 'alv.logger'
Logger\init 'silent'

hello_world = Cell.parse (Tag.parse '2'), { '', (ValueStream.sym 'hello'), ' ', (ValueStream.str 'world'), '' }
two_plus_two = Cell.parse (Tag.parse '3'), { '', (ValueStream.sym '+'), ' ', (ValueStream.num 2), ' ', (ValueStream.num 2), '' }

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

describe 'Cell', ->
  describe 'when cloned', ->
    parent = Tag.blank '1'
    with hello_world\clone parent
      it 'keeps children', ->
        assert.is.equal Cell, .__class
        assert.is.equal (ValueStream.sym 'hello'), \head!
        assert.is.same { ValueStream.str 'world' }, \tail!

      it 'clones the tag', ->
        assert.is.equal hello_world.tag, .tag.original
        assert.is.equal parent, .tag.parent

  describe 'when evaluated', ->
    it 'errors when empty', ->
      cell = Cell.parse {''}
      assert.has.error -> cell\eval globals

    it 'evaluates its head', ->
      head = ValueStream.sym 'trace'
      cell = Cell.parse { '', head, ' ', (ValueStream.sym 'true'), '' }

      s = spy.on head, 'eval'
      cell\eval globals
      assert.spy(s).was_called_with (match.is_ref head), (match.is_ref globals)

describe 'RootCell', ->
  test 'tag is always [0]', ->
    cell = Cell.parse_root {}
    assert.is.equal '[0]', cell.tag\stringify!

  test 'head is always "do"', ->
    cell = Cell.parse_root {}
    assert.is.equal (ValueStream.sym 'do'), cell\head!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.equal (ValueStream.sym 'do'), cell\head!

  test 'tail is all children', ->
    cell = Cell.parse_root {}
    assert.is.same {}, cell\tail!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.same { hello_world, two_plus_two },
                   cell\tail!
