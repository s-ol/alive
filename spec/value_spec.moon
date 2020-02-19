import Value, Result, Op, Action, Scope from require 'core'
import Logger from require 'logger'
Logger.init 'silent'

class TestOp extends Op
  new: (...) => super ...

class TestAction extends Action
  new: (...) =>

describe 'Value', ->
  describe 'wraps', ->
    test 'numbers', ->
      got = Value.wrap 3
      assert.is.equal 'num', got.type
      assert.is.equal 3, got.value

    test 'strings', ->
      got = Value.wrap "im a happy string"
      assert.is.equal 'str', got.type
      assert.is.equal "im a happy string", got.value

    test 'Values', ->
      pi = Value 'num', 3.14
      got = Value.wrap pi

      assert.is.equal pi, got

    test 'Opdefs', ->
      got = Value.wrap TestOp

      assert.is.equal 'opdef', got.type
      assert.is.equal TestOp, got.value

    test 'Bultins', ->
      got = Value.wrap TestAction

      assert.is.equal 'builtin', got.type
      assert.is.equal TestAction, got.value

    test 'Scopes', ->
      sub = Scope!
      got = Value.wrap sub

      assert.is.equal 'scope', got.type
      assert.is.equal sub, got.value

    test 'tables', ->
      pi = Value 'num', 3.14
      got = Value.wrap { :pi }

      assert.is.equal 'scope', got.type
      assert.is.equal pi, (got.value\get 'pi')\const!

  describe 'unwraps', ->
    test 'unwrap!', ->
      assert.is.equal 3.14, (Value.num 3.14)\unwrap!
      assert.is.equal 'hi', (Value.str 'hi')\unwrap!
      assert.is.equal 'hi', (Value.sym 'hi')\unwrap!

    test 'with type assert', ->
      assert.is.equal 3.14, (Value.num 3.14)\unwrap 'num'
      assert.is.equal 'hi', (Value.str 'hi')\unwrap 'str'
      assert.is.equal 'hi', (Value.sym 'hi')\unwrap 'sym'
      assert.has_error -> (Value.num 3.14)\unwrap 'sym'
      assert.has_error -> (Value.str 'hi')\unwrap 'num'
      assert.has_error -> (Value.sym 'hi')\unwrap 'str'

  describe 'checks equality', ->
    test 'using the type', ->
      val = Value 'num', 3
      assert.is.equal (Value.num 3), val
      assert.not.equal (Value.str '3'), val

      val = Value 'str', 'hello'
      assert.is.equal (Value.str 'hello'), val
      assert.not.equal (Value.sym 'hello'), val

    test 'using the value', ->
      val = Value 'num', 3
      assert.is.equal (Value.num 3), val
      assert.not.equal (Value.num 4), val

  describe 'evaluates literal', ->
    test 'numbers to consts', ->
      assert_noop = (val) ->
        assert.is.equal val, val\eval!\const!

      assert_noop Value.num 2
      assert_noop Value.str 'hello'

    test 'symbols in the scope', ->
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

  describe 'quotes literals', ->
    test 'as themselves', ->
      assert_noop = (val) -> assert.is.equal val, val\quote!

      assert_noop Value.num 2
      assert_noop Value.str 'hello'
      assert_noop Value.sym 'world'
