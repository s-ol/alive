import TestPilot from require 'spec.test_setup'

describe "thread macros", ->
  COPILOT = TestPilot!

  it "thread forward (->)", ->
    rt = COPILOT\eval_once '
    (import* math)
    #((/ (+ 10 2) 8) = 1.5)
    (-> 10
      (+ 2)
      (/ 8))'
    assert.is.true rt\is_const!
    assert.is.equal '<num= 1.5>', tostring rt.result

  it "thread last forward (->>)", ->
    rt = COPILOT\eval_once '
    (import* math)
    #((/ 10 (+ 2 2)) = 2.5)
    (->> 2
      (+ 2)
      (/ 10))'
    assert.is.true rt\is_const!
    assert.is.equal '<num= 2.5>', tostring rt.result
