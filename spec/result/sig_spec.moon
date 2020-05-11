import do_setup from require 'spec.test_setup'
import SigStream, Constant, RTNode, Scope, SimpleRegistry, T from require 'alv'
import Op, Builtin from require 'alv.base'

setup do_setup

describe 'SigStream', ->
  describe ':unwrap', ->
    it 'returns the raw value!', ->
      assert.is.equal 3.14, (SigStream T.num, 3.14)\unwrap!
      assert.is.equal 'hi', (SigStream T.str, 'hi')\unwrap!
      assert.is.equal 'hi', (SigStream T.sym, 'hi')\unwrap!

    test 'can assert the type', ->
      assert.is.equal 3.14, (SigStream T.num, 3.14)\unwrap T.num
      assert.is.equal 'hi', (SigStream T.str, 'hi')\unwrap T.str
      assert.is.equal 'hi', (SigStream T.sym, 'hi')\unwrap T.sym
      assert.has_error -> (SigStream T.num, 3.14)\unwrap T.sym
      assert.has_error -> (SigStream T.str, 'hi')\unwrap T.num
      assert.has_error -> (SigStream T.sym, 'hi')\unwrap T.str

    test 'has __call shorthand', ->
      assert.is.equal 3.14, (SigStream T.num, 3.14)!
      assert.is.equal 'hi', (SigStream T.str, 'hi')!
      assert.is.equal 'hi', (SigStream T.sym, 'hi')!
      assert.is.equal 3.14, (SigStream T.num, 3.14) T.num
      assert.is.equal 'hi', (SigStream T.str, 'hi') T.str
      assert.is.equal 'hi', (SigStream T.sym, 'hi') T.sym
      assert.has_error -> (SigStream T.num, 3.14) T.sym
      assert.has_error -> (SigStream T.str, 'hi') T.num
      assert.has_error -> (SigStream T.sym, 'hi') T.str

  describe 'overrides __eq', ->
    it 'compares the type', ->
      val = SigStream T.num, 3
      assert.is.equal (SigStream T.num, 3), val
      assert.not.equal (SigStream T.str, '3'), val

      val = SigStream T.str, 'hello'
      assert.is.equal (SigStream T.str, 'hello'), val
      assert.not.equal (SigStream T.sym, 'hello'), val

    it 'compares the value', ->
      val = SigStream T.num, 3
      assert.is.equal (SigStream T.num, 3), val
      assert.not.equal (SigStream T.num, 4), val

    it 'can be compared to a Constant', ->
      val = SigStream T.num, 3
      assert.is.equal (Constant.num 3), val
      assert.not.equal (Constant.num 4), val

      val = SigStream T.str, 'hello'
      assert.is.equal (Constant.str 'hello'), val
      assert.not.equal (Constant.sym 'hello'), val

  describe ':set', ->
    it 'sets the value', ->
      val = SigStream T.num, 3
      assert.is.equal (SigStream T.num, 3), val

      val\set 4
      assert.is.equal (SigStream T.num, 4), val
      assert.not.equal (SigStream T.num, 3), val

    it 'marks the value dirty', ->
      val = SigStream T.num, 3
      assert.is.false val\dirty!

      val\set 4
      assert.is.true val\dirty!

  describe ':fork', ->
    it 'is equal to the original', ->
      a = SigStream T.num, 2
      b = SigStream T.str, 'asdf'
      c = with SigStream T.weird, {}, '(raw)'
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
      a = SigStream T.num, 3
      b = with SigStream T.weird, {}, '(raw)'
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
