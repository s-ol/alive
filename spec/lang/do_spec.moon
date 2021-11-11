import TestPilot from require 'spec.test_setup'
import T, Struct, Array, Constant from require 'alv'

describe "do", ->
  COPILOT = TestPilot ''

  it "can be empty", ->
    rt = COPILOT\eval_once '(do)'
    assert.is.true rt\is_const!
    assert.is.nil rt.result

  it "returns the last result, if any", ->
    rt = COPILOT\eval_once '(do 1 2 3)'
    assert.is.true rt\is_const!
    assert.is.equal (Constant.num 3), rt.result

    rt = COPILOT\eval_once '(do 1 2 (def _ 3))'
    assert.is.true rt\is_const!
    assert.is.nil rt.result

  it "passes through side-effects", ->
    rt = COPILOT\eval_once '
      (import* time)
      (do
        (every 0.5 "bang! side-effect")
        3)'
    assert.is.false rt\is_const!
    assert.is.equal (Constant.num 3), rt.result

