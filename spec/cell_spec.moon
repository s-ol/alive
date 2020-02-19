import Cell, RootCell, Value, Scope, globals from require 'core'
import Registry from require 'core.registry'
import Logger from require 'logger'
Logger.init 'silent'

hello_world = Cell nil, { (Value.sym 'hello'), (Value.str 'world') }
two_plus_two = Cell nil, { (Value.sym '+'), (Value.num 2), (Value.num 2) }

describe 'Cell', ->
  it 'supports quoting', ->
    with hello_world\quote!
      assert.is.equal Cell, .__class
      assert.is.equal (Value.sym 'hello'), \head!
      assert.is.same { Value.str 'world' }, \tail!

    with two_plus_two\quote!
      assert.is.equal Cell, .__class
      assert.is.equal (Value.sym '+'), \head!
      assert.is.same { (Value.num 2), (Value.num 2) }, \tail!


describe 'RootCell', ->
  test 'head is always "do"', ->
    cell = RootCell\parse {}
    assert.is.equal (Value.sym 'do'), cell\head!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.equal (Value.sym 'do'), cell\head!

  test 'tail is all children', ->
    cell = RootCell\parse {}
    assert.is.same {}, cell\tail!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.same { hello_world, two_plus_two },
                   cell\tail!
