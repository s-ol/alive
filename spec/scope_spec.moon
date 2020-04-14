import Scope, ValueStream, Result from require 'alv'
import Op from require 'alv.base'
import Logger from require 'alv.logger'
Logger.init 'silent'

class TestOp extends Op
  new: (...) => super ...

wrap_res = (value) -> Result :value

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
      pi = ValueStream 'num', 3.14
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
      pi = ValueStream 'num', 3.14
      scope\set_raw 'math',  { :pi }

      got = (scope\get 'math')\const!
      assert.is.equal 'scope', got.type
      assert.is.equal Scope, got.value.__class
      assert.is.equal pi, (got.value\get 'pi')\const!
      assert.is.equal pi, (scope\get 'math/pi')\const!

  it 'wraps Values in from_table', ->
    pi = ValueStream 'num', 3.14
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

    pi = ValueStream 'num', 3.14
    b\set_raw 'test', pi
    a\set_raw 'child', b
    root\set_raw 'deep', a

    assert.is.equal pi, (root\get 'deep/child/test')\const!

  describe 'can set symbols', ->
    one = wrap_res ValueStream.num 1
    two = wrap_res ValueStream.num 2
    scope = Scope!

    it 'disallows re-setting symbols', ->
      scope\set 'test', one
      assert.is.equal one, scope\get 'test'

    it 'throws if overwriting', ->
      assert.has.error -> scope\set 'test', two
      assert.is.equal one, scope\get 'test'

  describe 'inheritance', ->
    root = Scope!
    root\set_raw 'hidden', 1234
    root\set_raw 'inherited', "inherited string"

    scope = Scope root

    it 'allows access', ->
      got = (scope\get 'inherited')\const!
      assert.is.equal 'str', got.type
      assert.is.equal "inherited string", got.value

    it 'can be shadowed', ->
      scope\set_raw 'hidden', "overwritten"

      got = (scope\get 'hidden')\const!
      assert.is.equal 'str', got.type
      assert.is.equal "overwritten", got.value

  describe 'dynamic inheritance', ->
    root = Scope!
    dyn_root = Scope!

    root\set_raw 'normal', 'normal'
    root\set_raw '*dynamic*', 'normal'
    dyn_root\set_raw 'normal', 'dynamic'
    dyn_root\set_raw '*dynamic*', 'dynamic'

    dyn_root\set_raw '*nested*', { value: 3 }

    it 'follows a different parent', ->
      merged = Scope root, dyn_root
      assert.is.equal 'normal', (merged\get 'normal').value!
      assert.is.equal 'dynamic', (merged\get '*dynamic*').value!

    it 'falls back to the immediate parent', ->
      merged = Scope root
      assert.is.equal 'normal', (merged\get '*dynamic*').value!

    it 'looks in self first', ->
      merged = Scope root
      merged\set_raw '*dynamic*', 'merged'
      assert.is.equal 'merged', (merged\get '*dynamic*').value!

    it 'can resolve nested', ->
      merged = Scope root, dyn_root
      assert.is.equal 3, (merged\get '*nested*/value').value!
