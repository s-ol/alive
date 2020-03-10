import Cell, RootCell from require 'core.cell'
import Value, Scope, Tag, SimpleRegistry, globals from require 'core'
import Logger from require 'logger'
Logger.init 'silent'

hello_world = Cell.parse (Tag.parse '2'), { '', (Value.sym 'hello'), ' ', (Value.str 'world'), '' }
two_plus_two = Cell.parse (Tag.parse '3'), { '', (Value.sym '+'), ' ', (Value.num 2), ' ', (Value.num 2), '' }

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

describe 'Cell', ->
  describe 'when quoted', ->
    with hello_world\quote!
      it 'stays equal', ->
        assert.is.equal Cell, .__class
        assert.is.equal (Value.sym 'hello'), \head!
        assert.is.same { Value.str 'world' }, \tail!

      it 'shares the tag', ->
        assert.is.equal hello_world.tag, .tag

    with two_plus_two\quote!
      it 'stays equal', ->
        assert.is.equal Cell, .__class
        assert.is.equal (Value.sym '+'), \head!
        assert.is.same { (Value.num 2), (Value.num 2) }, \tail!

      it 'shares the tag', ->
        assert.is.equal two_plus_two.tag, .tag

  describe 'when cloned', ->
    parent = Tag.blank '1'
    with hello_world\clone parent
      it 'keeps children', ->
        assert.is.equal Cell, .__class
        assert.is.equal (Value.sym 'hello'), \head!
        assert.is.same { Value.str 'world' }, \tail!

      it 'clones the tag', ->
        assert.is.equal hello_world.tag, .tag.original
        assert.is.equal parent, .tag.parent

  describe 'when evaluated', ->
    it 'errors when empty', ->
      cell = Cell.parse {''}
      assert.has.error -> cell\eval globals

    it 'evaluates its head', ->
      head = Value.sym 'trace'
      cell = Cell.parse { '', head, ' ', (Value.sym 'true'), '' }

      s = spy.on head, 'eval'
      cell\eval globals
      assert.spy(s).was_called_with (match.is_ref head), (match.is_ref globals)

describe 'RootCell', ->
  test 'tag is always [0]', ->
    cell = Cell.parse_root {}
    assert.is.equal '[0]', cell.tag\stringify!

  test 'head is always "do"', ->
    cell = Cell.parse_root {}
    assert.is.equal (Value.sym 'do'), cell\head!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.equal (Value.sym 'do'), cell\head!

  test 'tail is all children', ->
    cell = Cell.parse_root {}
    assert.is.same {}, cell\tail!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.same { hello_world, two_plus_two },
                   cell\tail!
