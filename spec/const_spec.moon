import Const, Op, Action, Scope from require 'core'
import Logger from require 'logger'
Logger.init 'silent'

class TestOp extends Op
  new: (...) => super ...

class TestAction extends Action
  new: (...) =>

describe 'Const', ->
  describe 'wraps', ->
    test 'numbers', ->
      got = Const.wrap 3
      assert.is.equal 'num', got.type
      assert.is.equal 3, got.value

    test 'strings', ->
      got = Const.wrap "im a happy string"
      assert.is.equal 'str', got.type
      assert.is.equal "im a happy string", got.value

    test 'Consts', ->
      pi = Const 'num', 3.14
      got = Const.wrap pi

      assert.is.equal pi, got

    test 'Opdefs', ->
      got = Const.wrap TestOp

      assert.is.equal 'opdef', got.type
      assert.is.equal TestOp, got.value

    test 'Bultins', ->
      got = Const.wrap TestAction

      assert.is.equal 'builtin', got.type
      assert.is.equal TestAction, got.value

    test 'Scopes', ->
      sub = Scope!
      got = Const.wrap sub

      assert.is.equal 'scope', got.type
      assert.is.equal sub, got.value

    test 'tables', ->
      pi = Const 'num', 3.14
      got = Const.wrap { :pi }

      assert.is.equal 'scope', got.type
      assert.is.equal pi, got.value\get 'pi'

  describe 'unwraps', ->
    test 'get!, getc!', ->
      assert.is.equal 3.14, (Const.num 3.14)\getc!
      assert.is.equal 'hi', (Const.str 'hi')\getc!
      assert.is.equal 'hi', (Const.sym 'hi')\getc!

      assert.is.equal 3.14, (Const.num 3.14)\get!
      assert.is.equal 'hi', (Const.str 'hi')\get!
      assert.is.equal 'hi', (Const.sym 'hi')\get!

    test 'with type assert', ->
      assert.is.equal 3.14, (Const.num 3.14)\getc 'num'
      assert.is.equal 'hi', (Const.str 'hi')\getc 'str'
      assert.is.equal 'hi', (Const.sym 'hi')\getc 'sym'
      assert.has_error -> (Const.num 3.14)\getc 'sym'
      assert.has_error -> (Const.str 'hi')\getc 'num'
      assert.has_error -> (Const.sym 'hi')\getc 'str'

      assert.is.equal 3.14, (Const.num 3.14)\get 'num'
      assert.is.equal 'hi', (Const.str 'hi')\get 'str'
      assert.is.equal 'hi', (Const.sym 'hi')\get 'sym'
      assert.has_error -> (Const.num 3.14)\get 'sym'
      assert.has_error -> (Const.str 'hi')\get 'num'
      assert.has_error -> (Const.sym 'hi')\get 'str'

  describe 'checks equality', ->
    test 'using the type', ->
      val = Const 'num', 3
      assert.is.equal (Const.num 3), val
      assert.not.equal (Const.str '3'), val

      val = Const 'str', 'hello'
      assert.is.equal (Const.str 'hello'), val
      assert.not.equal (Const.sym 'hello'), val

    test 'using the value', ->
      val = Const 'num', 3
      assert.is.equal (Const.num 3), val
      assert.not.equal (Const.num 4), val

  describe 'evaluates literal', ->
    test 'constants to themselves', ->
      assert_noop = (val) -> assert.is.equal val, val\eval!

      assert_noop Const.num 2
      assert_noop Const.str 'hello'

    test 'symbols in the scope', ->
      scope = with Scope!
        \set 'number', Const.num 3
        \set 'hello', Const.str "world"
        \set 'goodbye', Const.sym "again"

      assert_eval = (sym, val) ->
        const = Const.sym sym
        assert.is.equal val, const\eval scope

      assert_eval 'number', Const.num 3
      assert_eval 'hello', Const.str "world"
      assert_eval 'goodbye', Const.sym "again"

  describe 'quotes literals', ->
    test 'as themselves', ->
      assert_noop = (val) -> assert.is.equal val, val\quote!

      assert_noop Const.num 2
      assert_noop Const.str 'hello'
      assert_noop Const.sym 'world'
