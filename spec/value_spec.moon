import ValueStream, Result, Scope, SimpleRegistry from require 'alv'
import Op, Builtin from require 'alv.base'
import Logger from require 'alv.logger'
Logger\init 'silent'

class TestOp extends Op
  new: (...) => super ...

class TestBuiltin extends Builtin
  new: (...) =>

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

describe 'ValueStream', ->
  describe '.wrap', ->
    it 'wraps numbers', ->
      got = ValueStream.wrap 3
      assert.is.equal 'num', got.type
      assert.is.equal 3, got.value

    it 'wraps strings', ->
      got = ValueStream.wrap "im a happy string"
      assert.is.equal 'str', got.type
      assert.is.equal "im a happy string", got.value

    it 'wraps Values', ->
      pi = ValueStream 'num', 3.14
      got = ValueStream.wrap pi

      assert.is.equal pi, got

    it 'wraps Opdefs', ->
      got = ValueStream.wrap TestOp

      assert.is.equal 'opdef', got.type
      assert.is.equal TestOp, got.value

    it 'wraps Bultins', ->
      got = ValueStream.wrap TestBuiltin

      assert.is.equal 'builtin', got.type
      assert.is.equal TestBuiltin, got.value

    it 'wraps Scopes', ->
      sub = Scope!
      got = ValueStream.wrap sub

      assert.is.equal 'scope', got.type
      assert.is.equal sub, got.value

    it 'wraps tables', ->
      pi = ValueStream 'num', 3.14
      got = ValueStream.wrap { :pi }

      assert.is.equal 'scope', got.type
      assert.is.equal pi, (got.value\get 'pi')\const!

  describe ':unwrap', ->
    it 'returns the raw value!', ->
      assert.is.equal 3.14, (ValueStream.num 3.14)\unwrap!
      assert.is.equal 'hi', (ValueStream.str 'hi')\unwrap!
      assert.is.equal 'hi', (ValueStream.sym 'hi')\unwrap!

    test 'can assert the type', ->
      assert.is.equal 3.14, (ValueStream.num 3.14)\unwrap 'num'
      assert.is.equal 'hi', (ValueStream.str 'hi')\unwrap 'str'
      assert.is.equal 'hi', (ValueStream.sym 'hi')\unwrap 'sym'
      assert.has_error -> (ValueStream.num 3.14)\unwrap 'sym'
      assert.has_error -> (ValueStream.str 'hi')\unwrap 'num'
      assert.has_error -> (ValueStream.sym 'hi')\unwrap 'str'

    test 'has __call shorthand', ->
      assert.is.equal 3.14, (ValueStream.num 3.14)!
      assert.is.equal 'hi', (ValueStream.str 'hi')!
      assert.is.equal 'hi', (ValueStream.sym 'hi')!
      assert.is.equal 3.14, (ValueStream.num 3.14) 'num'
      assert.is.equal 'hi', (ValueStream.str 'hi') 'str'
      assert.is.equal 'hi', (ValueStream.sym 'hi') 'sym'
      assert.has_error -> (ValueStream.num 3.14) 'sym'
      assert.has_error -> (ValueStream.str 'hi') 'num'
      assert.has_error -> (ValueStream.sym 'hi') 'str'

  describe 'overrides __eq', ->
    it 'compares the type', ->
      val = ValueStream 'num', 3
      assert.is.equal (ValueStream.num 3), val
      assert.not.equal (ValueStream.str '3'), val

      val = ValueStream 'str', 'hello'
      assert.is.equal (ValueStream.str 'hello'), val
      assert.not.equal (ValueStream.sym 'hello'), val

    it 'compares the value', ->
      val = ValueStream 'num', 3
      assert.is.equal (ValueStream.num 3), val
      assert.not.equal (ValueStream.num 4), val

  describe ':set', ->
    it 'sets the value', ->
      val = ValueStream 'num', 3
      assert.is.equal (ValueStream.num 3), val

      val\set 4
      assert.is.equal (ValueStream.num 4), val
      assert.not.equal (ValueStream.num 3), val

    it 'marks the value dirty', ->
      val = ValueStream 'num', 3
      assert.is.false val\dirty!

      val\set 4
      assert.is.true val\dirty!

  describe ':eval', ->
    it 'turns numbers into consts', ->
      assert_noop = (val) ->
        assert.is.equal val, val\eval!\const!

      assert_noop ValueStream.num 2
      assert_noop ValueStream.str 'hello'

    it 'looks up symbols in the scope', ->
      scope = with Scope!
        \set 'number', Result value: ValueStream.num 3
        \set 'hello', Result value: ValueStream.str "world"
        \set 'goodbye', Result value: ValueStream.sym "again"

      assert_eval = (sym, val) ->
        const = ValueStream.sym sym
        assert.is.equal val, (const\eval scope)\const!

      assert_eval 'number', ValueStream.num 3
      assert_eval 'hello', ValueStream.str "world"
      assert_eval 'goodbye', ValueStream.sym "again"

  it ':quote s literals as themselves', ->
    assert_noop = (val) -> assert.is.equal val, val\quote!

    assert_noop ValueStream.num 2
    assert_noop ValueStream.str 'hello'
    assert_noop ValueStream.sym 'world'

  it ':clone sliterals as themselves', ->
    assert_noop = (val) -> assert.is.equal val, val\clone!

    assert_noop ValueStream.num 2
    assert_noop ValueStream.str 'hello'
    assert_noop ValueStream.sym 'world'

  describe ':fork', ->
    it 'is equal to the original', ->
      a = ValueStream.num 2
      b = ValueStream.str 'asdf'
      c = with ValueStream 'weird', {}, '(raw)'
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
      a = ValueStream.num 3
      b = with ValueStream 'weird', {}, '(raw)'
        \set {}

      aa, bb = a\fork!, b\fork!

      bb\set {false}

      assert.is.same {}, b!
      assert.is.same {false}, bb!
      assert.is.true b\dirty!
      assert.is.true bb\dirty!

      reg\next_tick!
      aa\set 4

      assert.is.equal 3, a!
      assert.is.equal 4, aa!
      assert.is.false a\dirty!
      assert.is.true aa\dirty!
