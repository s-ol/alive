import TestPilot from require 'spec.test_setup'
import T, Struct, Array, Constant from require 'alv'

describe "do", ->
  COPILOT = TestPilot ''

  it "can be empty", ->
    COPILOT.active_module\spit '(do)'
    COPILOT\tick!
    assert.is.true COPILOT.active_module.root\is_const!
    assert.is.nil COPILOT.active_module.root.result

  it "returns the last result, if any", ->
    COPILOT.active_module\spit '(do 1 2 3)'
    COPILOT\tick!
    assert.is.true COPILOT.active_module.root\is_const!
    assert.is.equal (Constant.num 3), COPILOT.active_module.root.result

    COPILOT.active_module\spit '(do 1 2 (trace 3))'
    COPILOT\tick!
    assert.is.true COPILOT.active_module.root\is_const!
    assert.is.nil COPILOT.active_module.root.result

  it "passes through side-effects", ->
    COPILOT.active_module\spit '
      (import* time)
      (do
        (every 0.5 "bang! side-effect")
        3)'
    COPILOT\tick!
    assert.is.false COPILOT.active_module.root\is_const!
    assert.is.equal (Constant.num 3), COPILOT.active_module.root.result

