import do_setup from require 'spec.test_setup'
import Constant, RTNode, Scope, SimpleRegistry, Primitive from require 'alv'
import Op, Builtin from require 'alv.base'

class TestOp extends Op
  new: (...) => super ...

class TestBuiltin extends Builtin
  new: (...) =>

setup do_setup

describe 'Constant', ->
  describe '.wrap', ->
    it 'wraps numbers', ->
      got = Constant.wrap 3
      assert.is.equal Primitive.num, got.type
      assert.is.equal 3, got.value

    it 'wraps strings', ->
      got = Constant.wrap "im a happy string"
      assert.is.equal Primitive.str, got.type
      assert.is.equal "im a happy string", got.value

    it 'wraps Constants', ->
      pi = Constant.num 3.14
      got = Constant.wrap pi

      assert.is.equal pi, got

    it 'wraps Opdefs', ->
      got = Constant.wrap TestOp

      assert.is.equal Primitive.op, got.type
      assert.is.equal TestOp, got.value

    it 'wraps Bultins', ->
      got = Constant.wrap TestBuiltin

      assert.is.equal Primitive.builtin, got.type
      assert.is.equal TestBuiltin, got.value

    it 'wraps Scopes', ->
      sub = Scope!
      got = Constant.wrap sub

      assert.is.equal Primitive.scope, got.type
      assert.is.equal sub, got.value

    it 'wraps tables', ->
      pi = Constant.num 3.14
      got = Constant.wrap { :pi }

      assert.is.equal Primitive.scope, got.type
      assert.is.equal pi, (got.value\get 'pi')\const!

  describe ':unwrap', ->
    it 'returns the raw value!', ->
      assert.is.equal 3.14, (Constant.num 3.14)\unwrap!
      assert.is.equal 'hi', (Constant.str 'hi')\unwrap!
      assert.is.equal 'hi', (Constant.sym 'hi')\unwrap!

    test 'can assert the type', ->
      assert.is.equal 3.14, (Constant.num 3.14)\unwrap Primitive.num
      assert.is.equal 'hi', (Constant.str 'hi')\unwrap Primitive.str
      assert.is.equal 'hi', (Constant.sym 'hi')\unwrap Primitive.sym
      assert.has_error -> (Constant.num 3.14)\unwrap Primitive.sym
      assert.has_error -> (Constant.str 'hi')\unwrap Primitive.num
      assert.has_error -> (Constant.sym 'hi')\unwrap Primitive.str

    test 'has __call shorthand', ->
      assert.is.equal 3.14, (Constant.num 3.14)!
      assert.is.equal 'hi', (Constant.str 'hi')!
      assert.is.equal 'hi', (Constant.sym 'hi')!
      assert.is.equal 3.14, (Constant.num 3.14) Primitive.num
      assert.is.equal 'hi', (Constant.str 'hi') Primitive.str
      assert.is.equal 'hi', (Constant.sym 'hi') Primitive.sym
      assert.has_error -> (Constant.num 3.14) Primitive.sym
      assert.has_error -> (Constant.str 'hi') Primitive.num
      assert.has_error -> (Constant.sym 'hi') Primitive.str

  describe 'overrides __eq', ->
    it 'compares the type', ->
      val = Constant.num 3
      assert.is.equal (Constant.num 3), val
      assert.not.equal (Constant.str '3'), val

      val = Constant.str 'hello'
      assert.is.equal (Constant.str 'hello'), val
      assert.not.equal (Constant.sym 'hello'), val

    it 'compares the value', ->
      val = Constant.num 3
      assert.is.equal (Constant.num 3), val
      assert.not.equal (Constant.num 4), val

  it ':dirty is always false', ->
    val = Constant.num 3
    assert.is.false val\dirty!

    val.value = 4
    assert.is.false val\dirty!

  describe ':eval', ->
    it 'turns numbers into consts', ->
      assert_noop = (val) ->
        assert.is.equal val, val\eval!\const!

      assert_noop Constant.num 2
      assert_noop Constant.str 'hello'

    it 'looks up symbols in the scope', ->
      scope = with Scope!
        \set 'number', RTNode result: Constant.num 3
        \set 'hello', RTNode result: Constant.str "world"
        \set 'goodbye', RTNode result: Constant.sym "again"

      assert_eval = (sym, val) ->
        const = Constant.sym sym
        assert.is.equal val, (const\eval scope)\const!

      assert_eval 'number', Constant.num 3
      assert_eval 'hello', Constant.str "world"
      assert_eval 'goodbye', Constant.sym "again"

  it ':clones literals as themselves', ->
    assert_noop = (val) -> assert.is.equal val, val\clone!

    assert_noop Constant.num 2
    assert_noop Constant.str 'hello'
    assert_noop Constant.sym 'world'

  describe ':fork', ->
    it 'is equal to the original', ->
      a = Constant.num 2
      b = Constant.str 'asdf'
      c = Constant (Primitive 'weird'), {}, '(raw)'

      aa, bb, cc = a\fork!, b\fork!, c\fork!
      assert.is.equal a, aa
      assert.is.equal b, bb
      assert.is.equal c, cc

      assert.is.false aa\dirty!
      assert.is.false bb\dirty!
      assert.is.false cc\dirty!

      assert.is.equal c.raw, cc.raw
