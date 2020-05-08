import do_setup from require 'spec.test_setup'
import SigStream, RTNode, Scope, SimpleRegistry from require 'alv'
import Op, Builtin from require 'alv.base'
import Primitive from require 'alv.types'

class TestOp extends Op
  new: (...) => super ...

class TestBuiltin extends Builtin
  new: (...) =>

setup do_setup

describe 'SigStream', ->
  describe ':unwrap', ->
    it 'returns the raw value!', ->
      assert.is.equal 3.14, (SigStream.num 3.14)\unwrap!
      assert.is.equal 'hi', (SigStream.str 'hi')\unwrap!
      assert.is.equal 'hi', (SigStream.sym 'hi')\unwrap!

    test 'can assert the type', ->
      assert.is.equal 3.14, (SigStream.num 3.14)\unwrap Primitive 'num'
      assert.is.equal 'hi', (SigStream.str 'hi')\unwrap Primitive 'str'
      assert.is.equal 'hi', (SigStream.sym 'hi')\unwrap Primitive 'sym'
      assert.has_error -> (SigStream.num 3.14)\unwrap Primitive 'sym'
      assert.has_error -> (SigStream.str 'hi')\unwrap Primitive 'num'
      assert.has_error -> (SigStream.sym 'hi')\unwrap Primitive 'str'

    test 'has __call shorthand', ->
      assert.is.equal 3.14, (SigStream.num 3.14)!
      assert.is.equal 'hi', (SigStream.str 'hi')!
      assert.is.equal 'hi', (SigStream.sym 'hi')!
      assert.is.equal 3.14, (SigStream.num 3.14) Primitive 'num'
      assert.is.equal 'hi', (SigStream.str 'hi') Primitive 'str'
      assert.is.equal 'hi', (SigStream.sym 'hi') Primitive 'sym'
      assert.has_error -> (SigStream.num 3.14) Primitive 'sym'
      assert.has_error -> (SigStream.str 'hi') Primitive 'num'
      assert.has_error -> (SigStream.sym 'hi') Primitive 'str'

  describe 'overrides __eq', ->
    it 'compares the type', ->
      val = SigStream.num 3
      assert.is.equal (SigStream.num 3), val
      assert.not.equal (SigStream.str '3'), val

      val = SigStream.str 'hello'
      assert.is.equal (SigStream.str 'hello'), val
      assert.not.equal (SigStream.sym 'hello'), val

    it 'compares the value', ->
      val = SigStream.num 3
      assert.is.equal (SigStream.num 3), val
      assert.not.equal (SigStream.num 4), val

  describe ':set', ->
    it 'sets the value', ->
      val = SigStream.num 3
      assert.is.equal (SigStream.num 3), val

      val\set 4
      assert.is.equal (SigStream.num 4), val
      assert.not.equal (SigStream.num 3), val

    it 'marks the value dirty', ->
      val = SigStream.num 3
      assert.is.false val\dirty!

      val\set 4
      assert.is.true val\dirty!

  describe ':fork', ->
    it 'is equal to the original', ->
      a = SigStream.num 2
      b = SigStream.str 'asdf'
      c = with SigStream 'weird', {}, '(raw)'
        \set {}

      aa, bb, cc = a\fork!, b\fork!, c\fork!
      assert.is.equal a, aa
      assert.is.equal b, bb
      assert.is.equal c, cc

      assert.is.false aa\dirty!
      assert.is.false bb\dirty!
      assert.is.true cc\dirty!

      assert.is.equal c.raw, cc.raw

    it 'isolates the original from the fork', ->
      a = SigStream.num 3
      b = with SigStream 'weird', {}, '(raw)'
        \set {}

      aa, bb = a\fork!, b\fork!

      bb\set {false}

      assert.is.same {}, b!
      assert.is.same {false}, bb!
      assert.is.true b\dirty!
      assert.is.true bb\dirty!

      COPILOT\next_tick!
      aa\set 4

      assert.is.equal 3, a!
      assert.is.equal 4, aa!
      assert.is.false a\dirty!
      assert.is.true aa\dirty!
