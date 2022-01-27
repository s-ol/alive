import TestPilot from require 'spec.test_setup'

describe "thread macros", ->
  COPILOT = TestPilot!

  it "thread forward (->)", ->
    rt = COPILOT\eval_once '
    (import* math)
    #((/ (+ 10 2) 2) = 6)
    (-> 10
      (+ 2)
      (/ 2))'
    assert.is.true rt\is_const!
    assert.is.equal '<num= 6.0>', tostring rt.result

  it "thread last forward (->>)", ->
    rt = COPILOT\eval_once '
    (import* math)
    #((/ 10 (+ 2 3)) = 2)
    (->> 3
      (+ 2)
      (/ 10))'
    assert.is.true rt\is_const!
    assert.is.equal '<num= 2.0>', tostring rt.result
