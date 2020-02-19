import Scope, Value, Op from require 'core'
import Logger from require 'logger'
Logger.init 'silent'

class TestOp extends Op
  new: (...) => super ...

describe 'Scope', ->
  describe 'constifies', ->
    scope = Scope!

    test 'numbers', ->
      scope\set_raw 'num', 3

      got = (scope\get 'num')\const!
      assert.is.equal 'num', got.type
      assert.is.equal 3, got.value

    test 'strings', ->
      scope\set_raw 'str', "im a happy string"

      got = (scope\get 'str')\const!
      assert.is.equal 'str', got.type
      assert.is.equal "im a happy string", got.value

    test 'Values', ->
      pi = Value 'num', 3.14
      scope\set_raw 'pi', pi

      assert.is.equal pi, (scope\get 'pi')\const!

    test 'Opdefs', ->
      scope\set_raw 'test', TestOp

      got = (scope\get 'test')\const!
      assert.is.equal 'opdef', got.type
      assert.is.equal TestOp, got.value

    test 'Scopes', ->
      sub = Scope!
      scope\set_raw 'sub', sub

      got = (scope\get 'sub')\const!
      assert.is.equal 'scope', got.type
      assert.is.equal sub, got.value

    test 'tables', ->
      pi = Value 'num', 3.14
      scope\set_raw 'math',  { :pi }

      got = (scope\get 'math')\const!
      assert.is.equal 'scope', got.type
      assert.is.equal Scope, got.value.__class
      assert.is.equal pi, (got.value\get 'pi')\const!
      assert.is.equal pi, (scope\get 'math/pi')\const!

  it 'wraps Values in from_table', ->
    pi = Value 'num', 3.14
    scope = Scope.from_table {
      num: 3
      str: "im a happy string"
      :pi
      math: :pi
      test: TestOp
    }

    got = (scope\get 'num')\const!
    assert.is.equal 'num', got.type
    assert.is.equal 3, got.value

    got = (scope\get 'str')\const!
    assert.is.equal 'str', got.type
    assert.is.equal "im a happy string", got.value

    assert.is.equal pi, (scope\get 'pi')\const!

    got = (scope\get 'test')\const!
    assert.is.equal 'opdef', got.type
    assert.is.equal TestOp, got.value

    got = (scope\get 'math')\const!
    assert.is.equal 'scope', got.type
    assert.is.equal pi, (scope\get 'math/pi')\const!

  it 'gets from nested scopes', ->
    root = Scope!
    a = Scope!
    b = Scope!

    pi = Value 'num', 3.14
    b\set_raw 'test', pi
    a\set_raw 'child', b
    root\set_raw 'deep', a

    assert.is.equal pi, (root\get 'deep/child/test')\const!

  describe 'inheritance', ->
    root = Scope!
    root\set_raw 'hidden', 1234
    root\set_raw 'inherited', "inherited string"

    scope = Scope nil, root

    it 'allows access', ->
      got = (scope\get 'inherited')\const!
      assert.is.equal 'str', got.type
      assert.is.equal "inherited string", got.value

    it 'can keep defs', ->
      scope\set_raw 'hidden', "overwritten"

      got = (scope\get 'hidden')\const!
      assert.is.equal 'str', got.type
      assert.is.equal "overwritten", got.value
