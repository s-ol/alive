import do_setup from require 'spec.test_setup'
import Constant, RTNode, Scope, SimpleRegistry, T from require 'alv'
import Op, Builtin from require 'alv.base'

class TestOp extends Op
  new: (...) => super ...

class TestBuiltin extends Builtin
  new: (...) =>

setup do_setup

describe 'Constant', ->
  it 'requires a value', ->
    assert.has.error -> Constant.num!
    assert.has.error -> Constant T.num
    assert.has.no.error -> Constant T.bool, false

  it 'stringifies well', ->
    assert.is.equal "<num= 4>", tostring Constant.num 4
    assert.is.equal "<bool= true>", tostring Constant.bool true
    assert.is.equal "<bool= false>", tostring Constant.bool false

  describe '.wrap', ->
    it 'wraps numbers', ->
      got = Constant.wrap 3
      assert.is.equal T.num, got.type
      assert.is.equal 3, got.value

    it 'wraps strings', ->
      got = Constant.wrap "im a happy string"
      assert.is.equal T.str, got.type
      assert.is.equal "im a happy string", got.value

    it 'wraps Constants', ->
      pi = Constant.num 3.14
      got = Constant.wrap pi

      assert.is.equal pi, got

    it 'wraps Opdefs', ->
      got = Constant.wrap TestOp

      assert.is.equal T.opdef, got.type
      assert.is.equal TestOp, got.value

    it 'wraps Bultins', ->
      got = Constant.wrap TestBuiltin

      assert.is.equal T.builtin, got.type
      assert.is.equal TestBuiltin, got.value

    it 'wraps Scopes', ->
      sub = Scope!
      got = Constant.wrap sub

      assert.is.equal T.scope, got.type
      assert.is.equal sub, got.value

    it 'wraps tables', ->
      pi = Constant.num 3.14
      got = Constant.wrap { :pi }

      assert.is.equal T.scope, got.type
      assert.is.equal pi, (got.value\get 'pi')\const!

  describe ':unwrap', ->
    it 'returns the raw value!', ->
      assert.is.equal 3.14, (Constant.num 3.14)\unwrap!
      assert.is.equal 'hi', (Constant.str 'hi')\unwrap!
      assert.is.equal 'hi', (Constant.sym 'hi')\unwrap!

    test 'can assert the type', ->
      assert.is.equal 3.14, (Constant.num 3.14)\unwrap T.num
      assert.is.equal 'hi', (Constant.str 'hi')\unwrap T.str
      assert.is.equal 'hi', (Constant.sym 'hi')\unwrap T.sym
      assert.has_error -> (Constant.num 3.14)\unwrap T.sym
      assert.has_error -> (Constant.str 'hi')\unwrap T.num
      assert.has_error -> (Constant.sym 'hi')\unwrap T.str

    test 'has __call shorthand', ->
      assert.is.equal 3.14, (Constant.num 3.14)!
      assert.is.equal 'hi', (Constant.str 'hi')!
      assert.is.equal 'hi', (Constant.sym 'hi')!
      assert.is.equal 3.14, (Constant.num 3.14) T.num
      assert.is.equal 'hi', (Constant.str 'hi') T.str
      assert.is.equal 'hi', (Constant.sym 'hi') T.sym
      assert.has_error -> (Constant.num 3.14) T.sym
      assert.has_error -> (Constant.str 'hi') T.num
      assert.has_error -> (Constant.sym 'hi') T.str

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
      c = Constant T.weird, {}, '(raw)'

      aa, bb, cc = a\fork!, b\fork!, c\fork!
      assert.is.equal a, aa
      assert.is.equal b, bb
      assert.is.equal c, cc

      assert.is.false aa\dirty!
      assert.is.false bb\dirty!
      assert.is.false cc\dirty!

      assert.is.equal c.raw, cc.raw
