import Value, Result, Scope, SimpleRegistry from require 'core'
import Op, Action from require 'core.base'
import Logger from require 'logger'
Logger.init 'silent'

class TestOp extends Op
  new: (...) => super ...

class TestAction extends Action
  new: (...) =>

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

describe 'Value', ->
  describe '.wrap', ->
    it 'wraps numbers', ->
      got = Value.wrap 3
      assert.is.equal 'num', got.type
      assert.is.equal 3, got.value

    it 'wraps strings', ->
      got = Value.wrap "im a happy string"
      assert.is.equal 'str', got.type
      assert.is.equal "im a happy string", got.value

    it 'wraps Values', ->
      pi = Value 'num', 3.14
      got = Value.wrap pi

      assert.is.equal pi, got

    it 'wraps Opdefs', ->
      got = Value.wrap TestOp

      assert.is.equal 'opdef', got.type
      assert.is.equal TestOp, got.value

    it 'wraps Bultins', ->
      got = Value.wrap TestAction

      assert.is.equal 'builtin', got.type
      assert.is.equal TestAction, got.value

    it 'wraps Scopes', ->
      sub = Scope!
      got = Value.wrap sub

      assert.is.equal 'scope', got.type
      assert.is.equal sub, got.value

    it 'wraps tables', ->
      pi = Value 'num', 3.14
      got = Value.wrap { :pi }

      assert.is.equal 'scope', got.type
      assert.is.equal pi, (got.value\get 'pi')\const!

  describe ':unwrap', ->
    it 'returns the raw value!', ->
      assert.is.equal 3.14, (Value.num 3.14)\unwrap!
      assert.is.equal 'hi', (Value.str 'hi')\unwrap!
      assert.is.equal 'hi', (Value.sym 'hi')\unwrap!

    test 'can assert the type', ->
      assert.is.equal 3.14, (Value.num 3.14)\unwrap 'num'
      assert.is.equal 'hi', (Value.str 'hi')\unwrap 'str'
      assert.is.equal 'hi', (Value.sym 'hi')\unwrap 'sym'
      assert.has_error -> (Value.num 3.14)\unwrap 'sym'
      assert.has_error -> (Value.str 'hi')\unwrap 'num'
      assert.has_error -> (Value.sym 'hi')\unwrap 'str'

    test 'has __call shorthand', ->
      assert.is.equal 3.14, (Value.num 3.14)!
      assert.is.equal 'hi', (Value.str 'hi')!
      assert.is.equal 'hi', (Value.sym 'hi')!
      assert.is.equal 3.14, (Value.num 3.14) 'num'
      assert.is.equal 'hi', (Value.str 'hi') 'str'
      assert.is.equal 'hi', (Value.sym 'hi') 'sym'
      assert.has_error -> (Value.num 3.14) 'sym'
      assert.has_error -> (Value.str 'hi') 'num'
      assert.has_error -> (Value.sym 'hi') 'str'

  describe 'overrides __eq', ->
    it 'compares the type', ->
      val = Value 'num', 3
      assert.is.equal (Value.num 3), val
      assert.not.equal (Value.str '3'), val

      val = Value 'str', 'hello'
      assert.is.equal (Value.str 'hello'), val
      assert.not.equal (Value.sym 'hello'), val

    it 'compares the value', ->
      val = Value 'num', 3
      assert.is.equal (Value.num 3), val
      assert.not.equal (Value.num 4), val

  describe ':set', ->
    it 'sets the value', ->
      val = Value 'num', 3
      assert.is.equal (Value.num 3), val

      val\set 4
      assert.is.equal (Value.num 4), val
      assert.not.equal (Value.num 3), val

    it 'marks the value dirty', ->
      val = Value 'num', 3
      assert.is.false val\dirty!

      val\set 4
      assert.is.true val\dirty!

  describe ':eval', ->
    it 'turns numbers into consts', ->
      assert_noop = (val) ->
        assert.is.equal val, val\eval!\const!

      assert_noop Value.num 2
      assert_noop Value.str 'hello'

    it 'looks up symbols in the scope', ->
      scope = with Scope!
        \set 'number', Result value: Value.num 3
        \set 'hello', Result value: Value.str "world"
        \set 'goodbye', Result value: Value.sym "again"

      assert_eval = (sym, val) ->
        const = Value.sym sym
        assert.is.equal val, (const\eval scope)\const!

      assert_eval 'number', Value.num 3
      assert_eval 'hello', Value.str "world"
      assert_eval 'goodbye', Value.sym "again"

  it ':quote s literals as themselves', ->
    assert_noop = (val) -> assert.is.equal val, val\quote!

    assert_noop Value.num 2
    assert_noop Value.str 'hello'
    assert_noop Value.sym 'world'

  it ':clone sliterals as themselves', ->
    assert_noop = (val) -> assert.is.equal val, val\clone!

    assert_noop Value.num 2
    assert_noop Value.str 'hello'
    assert_noop Value.sym 'world'

  describe ':fork', ->
    it 'is equal to the original', ->
      a = Value.num 2
      b = Value.str 'asdf'
      c = with Value 'weird', {}, '(raw)'
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
      a = Value.num 3
      b = with Value 'weird', {}, '(raw)'
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
