import TestPilot from require 'spec.test_setup'

describe "do", ->
  COPILOT = TestPilot!

  it "can be empty", ->
    with COPILOT\eval_once '(do)'
      assert.is.true \is_const!
      assert.is.nil .result

  it "returns the last result, if any", ->
    with COPILOT\eval_once '(do 1 2 3)'
      assert.is.true \is_const!
      assert.is.equal '<num= 3>', tostring .result

    with COPILOT\eval_once '(do 1 2 (def _ 3))'
      assert.is.true \is_const!
      assert.is.nil .result

  it "passes through side-effects", ->
    with COPILOT\eval_once '
        (import* time)
        (do
          (every 0.5 "bang! side-effect")
          3)'
      assert.is.false \is_const!
      assert.is.equal '<num= 3>', tostring .result
