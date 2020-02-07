import Cell, RootCell, Const  from require 'base'
import Scope from require 'scope'
import Registry from require 'registry'
import Logger from require 'logger'
Logger.init 'silent'

hello_world = Cell nil, { (Const.sym 'hello'), (Const.str 'world') }
two_plus_two = Cell nil, { (Const.sym '+'), (Const.num 2), (Const.num 2) }


describe 'Cell', ->
  describe 'quoting', ->
    it 'quotes children', ->
      reg = mock register: =>
      with hello_world\quote nil, reg
        assert.is.equal Cell, .__class
        assert.is.equal (Const.sym 'hello'), \head!
        assert.is.same { Const.str 'world' }, \tail!

      with two_plus_two\quote nil, reg
        assert.is.equal Cell, .__class
        assert.is.equal (Const.sym '+'), \head!
        assert.is.same { (Const.num 2), (Const.num 2) }, \tail!

    it 'registers recursively', ->
      root = Cell nil, { (Const.sym 'out'), hello_world, two_plus_two }

      reg = mock register: =>
      root\quote nil, reg

      (assert.spy reg.register).was.called_with reg, root, nil
      (assert.spy reg.register).was.called_with reg, hello_world, nil
      (assert.spy reg.register).was.called_with reg, two_plus_two, nil

    it 'passes parsed tag', ->
      root = Cell (Const.num 2), { (Const.sym 'out'), hello_world, two_plus_two }

      reg = mock register: =>
      root\quote nil, reg

      (assert.spy reg.register).was.called_with reg, root, (Const.num 2)

  describe 'evaluation', ->
    registry = Registry!
    registry.globals\use Scope.from_table require 'lib.math'

    local op, action

    it 'instantiates the op + action', ->
      op = two_plus_two\eval registry.globals, registry
      action = registry.map[two_plus_two.tag.value]

      assert.is.equal 'add', op.__class.__name
      assert.is.equal 'op_invoke', action.__class.__name
      registry\step!

    it 'calls :setup() when parameters change', ->
      two_plus_two.children[3] = Const.num 3

      s = spy.on op, 'setup'
      assert.is.equal op, two_plus_two\eval registry.globals, registry
      assert.is.equal action, registry.map[two_plus_two.tag.value]
      (assert.spy s).was.called_with (match.is_ref op), (Const.num 2), (Const.num 3)
      registry\step!

    it 'calls :destroy() when opdef changes', ->
      two_plus_two.children[1] = Const.sym 'sub'
      two_plus_two.children[2] = Const.num 6

      s = spy.on op, 'destroy'
      assert.not.equal op, two_plus_two\eval registry.globals, registry
      assert.is.equal action, registry.map[two_plus_two.tag.value]
      assert.is.equal 'sub', action.op.__class.__name
      (assert.spy s).was.called_with match.is_ref op

describe 'RootCell', ->
  test 'head is always "do"', ->
    cell = RootCell\parse {}
    assert.is.equal (Const.sym 'do'), cell\head!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.equal (Const.sym 'do'), cell\head!

  test 'tail is all children', ->
    cell = RootCell\parse {}
    assert.is.same {}, cell\tail!

    cell = RootCell nil, { hello_world, two_plus_two }
    assert.is.same { hello_world, two_plus_two },
                   cell\tail!
