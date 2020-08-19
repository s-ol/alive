import TestPilot from require 'spec.test_setup'
import T, Struct, Array, Constant from require 'alv'

describe "function", ->
  COPILOT = TestPilot ''

  it "returns constant results when constant", ->
    rt = COPILOT\eval_once '
    (import* math)

    (defn my-plus (a b)
      (+ a b))

    (my-plus 2 3)'
    assert.is.true rt\is_const!
    assert.is.equal (Constant.num 5), rt.result

  it "checks argument arity when invoked", ->
    err = assert.has.error -> COPILOT\eval_once '
    ([1]import* math)

    ([2]defn my-plus (a b)
      ([4]+ a b))

    ([3]my-plus 2)'
    assert.matches "argument error: expected 2 arguments, found 1", err
    assert.matches "while invoking function 'my%-plus' at %[3%]", err

    err = assert.has.error -> COPILOT\eval_once '
    ([1]import* math)

    ([2]defn my-plus (a b)
      ([4]+ a b))

    ([3]my-plus 2 3 4)'
    assert.matches "argument error: expected 2 arguments, found 3", err
    assert.matches "while invoking function 'my%-plus' at %[3%]", err

  it "can be anonymously invoked", ->
    rt = COPILOT\eval_once '
    ([1]
      ([2]fn (a b) b)
      3 4)'
    assert.is.equal (Constant.num 4), rt\const!

    err = assert.has.error -> COPILOT\eval_once '
    ([1]
      ([2]fn (a b) b)
      3)'
    assert.matches "argument error: expected 2 arguments, found 1", err
    assert.matches "while invoking function %(unnamed%) at %[1%]", err
