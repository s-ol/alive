import TestPilot from require 'spec.test_setup'
import T, Struct, Array, Constant from require 'alv'

describe "if", ->
  COPILOT = TestPilot!

  it "checks truthiness", ->
    for truthy in *{'true', '1', '-1', '1234', '(array 1 2 3)', '"test"', '""'}
      with COPILOT\eval_once "(if #{truthy} 'yes' 'no')"
        assert.is.true \is_const!
        assert.is.equal 'yes', .result!

    for falsy in *{'false', '0'}
      with COPILOT\eval_once "(if #{falsy} 'yes' 'no')"
        assert.is.true \is_const!
        assert.is.equal 'no', .result!

  it "can be used without else clause", ->
    with COPILOT\eval_once '(if true "yes")'
      assert.is.true \is_const!
      assert.is.equal 'yes', .result!

    with COPILOT\eval_once '(if false "yes")'
      assert.is.true \is_const!
      assert.is.equal nil, .result

  it "doesn't evaluate the untaken branch", ->
    with COPILOT\eval_once '(if true "yes" (error/doesnt-exist))'
      assert.is.true \is_const!
      assert.is.equal 'yes', .result!

    with COPILOT\eval_once '(if false (error/doesnt-exist) "no")'
      assert.is.true \is_const!
      assert.is.equal 'no', .result!

  it "errors on non-const choice", ->
    err = assert.has.error ->
      COPILOT\eval_once '(import* time) (if (ramp 1) "yes" "no")'
    assert.matches "'if'%-expression needs to be constant", err

  it "forwards any result", ->
    with COPILOT\eval_once '
        (import* time)
        (if true (every 1 (array 1 2 3)))'
      assert.is.false \is_const!
      assert.is.equal '<num[3]! nil>', tostring .result

describe "when", ->
  COPILOT = TestPilot!

  it "checks truthiness", ->
    for truthy in *{'true', '1', '-1', '1234', '(array 1 2 3)', '"test"', '""'}
      with COPILOT\eval_once "(when #{truthy} 'yes')"
        assert.is.true \is_const!
        assert.is.equal 'yes', .result!

    for falsy in *{'false', '0'}
      with COPILOT\eval_once "(when #{falsy} 'yes')"
        assert.is.true \is_const!
        assert.is.nil .result

  it "doesn't evaluate if falsy", ->
    with COPILOT\eval_once '(when false (error/doesnt-exist))'
      assert.is.true \is_const!
      assert.is.nil, .result

    with COPILOT\eval_once '
        (when false
          (error/doesnt-exist)
          (error/doesnt-exist)
          (error/doesnt-exist))'
      assert.is.true \is_const!
      assert.is.nil, .result

  it "errors on non-const choice", ->
    err = assert.has.error ->
      COPILOT\eval_once '(import* time) (when (ramp 1) 1 2 3)'
    assert.matches "'when'%-expression needs to be constant", err

  it "forwards any result", ->
    with COPILOT\eval_once '
        (import* time)
        (when true
          (every 1 (array 1 2 3))
          1 2 3)'
      assert.is.false \is_const!
      assert.is.equal '<num~ 3>', tostring .result

    with COPILOT\eval_once '(when true (array 1 2 3))'
      assert.is.true \is_const!
      assert.is.equal '<num[3]= [1 2 3]>', tostring .result

