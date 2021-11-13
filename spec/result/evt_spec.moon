import do_setup from require 'spec.test_setup'
import EvtStream, RTNode, Scope, SimpleRegistry, T from require 'alv'
import Op, Builtin from require 'alv.base'

setup do_setup

describe 'EvtStream', ->
  it 'stringifies well', ->
    number = EvtStream T.num
    assert.is.equal "<num! nil>", tostring number

    number\set 4
    assert.is.equal "<num! 4>", tostring number

    bool = EvtStream T.bool
    bool\set true
    assert.is.equal "<bool! true>", tostring bool

    COPILOT\next_tick!

    bool\set false
    assert.is.equal "<bool! false>", tostring bool

  describe ':unwrap', ->
    it 'returns the set value', ->
      stream = EvtStream T.num
      assert.is.nil stream\unwrap!

      stream\set 3.14
      assert.is.equal 3.14, stream\unwrap!

    it 'returns nil if not dirty', ->
      stream = EvtStream T.num
      assert.is.nil stream\unwrap!

      stream\set 3.14
      COPILOT\next_tick!
      assert.is.nil stream\unwrap!

    test 'can assert the type', ->
      assert.is.nil (EvtStream T.num)\unwrap T.num
      assert.is.nil (EvtStream T.str)\unwrap T.str
      assert.is.nil (EvtStream T.sym)\unwrap T.sym
      assert.has_error -> (EvtStream T.num)\unwrap T.sym
      assert.has_error -> (EvtStream T.str)\unwrap T.num
      assert.has_error -> (EvtStream T.sym)\unwrap T.str

    test 'has __call shorthand', ->
      stream = EvtStream T.num
      assert.is.nil stream!

      stream\set 3.14
      assert.is.equal 3.14, stream!

  describe ':set', ->
    it 'sets the value', ->
      stream = EvtStream T.num
      assert.is.false stream\dirty!

      stream\set 4
      assert.is.equal 4, stream\unwrap!
      assert.is.true stream\dirty!

      COPILOT\next_tick!

      assert.is.false stream\dirty!
      stream\set 3
      assert.is.equal 3, stream\unwrap!
      assert.is.true stream\dirty!

    it 'ignores nil values', ->
      stream = EvtStream T.num
      assert.is.nil stream\unwrap!
      assert.is.false stream\dirty!

      stream\set!
      assert.is.nil stream\unwrap!
      assert.is.false stream\dirty!

      stream\set nil
      assert.is.nil stream\unwrap!
      assert.is.false stream\dirty!

      stream\set false
      assert.is.equal false, stream\unwrap!
      assert.is.true stream\dirty!

    it 'errors when set twice', ->
      stream = EvtStream T.num
      stream\set 1
      assert.has.error -> stream\set 2
      assert.is.equal 1, stream\unwrap!

    it 'resets on the next tick', ->
      stream = EvtStream T.num
      stream\set 1

      COPILOT\next_tick!

      assert.is.false stream\dirty!
      stream\set 2
      assert.is.equal 2, stream\unwrap!
      assert.is.true stream\dirty!

  describe ':fork', ->
    it 'is clean', ->
      a = EvtStream T.num
      b = EvtStream T.str
      b\set 'asdf'

      aa, bb = a\fork!, b\fork!
      assert.is.nil aa!
      assert.is.nil bb!
      assert.is.false aa\dirty!
      assert.is.false bb\dirty!

    it 'leaves the original', ->
      a = EvtStream T.num
      b = EvtStream T.str
      b\set 'asdf'

      aa, bb = a\fork!, b\fork!
      assert.is.nil a!
      assert.is.equal 'asdf', b!
      assert.is.false a\dirty!
      assert.is.true b\dirty!

    it 'isolates the original from the fork', ->
      a = EvtStream T.num
      b = EvtStream T.str

      aa, bb = a\fork!, b\fork!
      a\set 1
      bb\set 2

      assert.is.equal 1, a!
      assert.is.true a\dirty!
      assert.is.nil aa!
      assert.is.false aa\dirty!

      assert.is.equal 2, bb!
      assert.is.true bb\dirty!
      assert.is.nil b!
      assert.is.false b\dirty!
