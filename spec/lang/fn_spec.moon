import TestPilot from require 'spec.test_setup'
import T, Struct, Array, Constant from require 'alv'

describe "function", ->
  COPILOT = TestPilot ''

  it "returns constant results when constant", ->
    COPILOT.active_module\spit '
    (import* math)

    (defn my-plus (a b)
      (+ a b))

    (my-plus 2 3)'
    COPILOT\tick!
    assert.is.true COPILOT.active_module.root\is_const!
    result = assert COPILOT.active_module.root.result
    assert.is.equal (Constant.num 5), result

  it "checks argument arity when invoked", ->
    COPILOT.active_module\spit '
    ([1]import* math)

    ([2]defn my-plus (a b)
      ([4]+ a b))

    ([3]my-plus 2)'
    err = assert.has.error COPILOT\tick
    assert.matches "argument error: expected 2 arguments, found 1", err
    assert.matches "while invoking function 'my%-plus' at %[3%]", err

    COPILOT.active_module\spit '
    ([1]import* math)

    ([2]defn my-plus (a b)
      ([4]+ a b))

    ([3]my-plus 2 3 4)'
    err = assert.has.error COPILOT\tick
    assert.matches "argument error: expected 2 arguments, found 3", err
    assert.matches "while invoking function 'my%-plus' at %[3%]", err

  it "can be anonymously invoked", ->
    COPILOT.active_module\spit '
    ([1]
      ([2]fn (a b) b)
      3 4)'
    COPILOT\tick!
    assert.is.equal (Constant.num 4), COPILOT.active_module.root\const!

    COPILOT.active_module\spit '
    ([1]
      ([2]fn (a b) b)
      3)'
    err = assert.has.error COPILOT\tick
    assert.matches "argument error: expected 2 arguments, found 1", err
    assert.matches "while invoking function %(unnamed%) at %[1%]", err
