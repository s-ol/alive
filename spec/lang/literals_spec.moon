import TestPilot from require 'spec.test_setup'
import T, Struct, Array, Constant from require 'alv'

describe "literal", ->
  test = TestPilot '
    (def str "hello"
         num   2
         bool  true
         curl  ([5]struct "a" 2 "b" false)
         sqre  ([7]array 1 2 3 4))
    (export*)'

  assert.is.true test.active_module.root\is_const!
  scope = (assert test.active_module.root.result)\unwrap T.scope

  it 'string', ->
    assert.is.equal (Constant.str 'hello'), (scope\get 'str')\const!

  it 'number', ->
    assert.is.equal (Constant.num 2), (scope\get 'num')\const!

  it 'boolean', ->
    assert.is.equal (Constant.bool true), (scope\get 'bool')\const!

  it 'structs', ->
    struct = (scope\get 'curl')\const!
    assert.is.equal (Struct a: T.num, b: T.bool), struct.type
    assert.is.same { a: 2, b: false }, struct!

  it 'arrays', ->
    array = (scope\get 'sqre')\const!
    assert.is.equal (Array 4, T.num), array.type
    assert.is.same {1, 2, 3, 4}, array!
