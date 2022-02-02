import TestPilot from require 'spec.test_setup'
import T, Array, Constant from require 'alv'

describe "math", ->
  test = TestPilot '', '(import* math)\n'
  TRUE = T.bool\mk_const true
  FALSE = T.bool\mk_const false

  it "+ adds", ->
    with COPILOT\eval_once '(+ 1 1)'
      assert.is.true \is_const!
      assert.is.equal '<num= 2>', tostring .result

    with COPILOT\eval_once '(+ 2 3 0 1)'
      assert.is.true \is_const!
      assert.is.equal '<num= 6>', tostring .result

describe "lin-math", ->
  test = TestPilot '', '(import* lin-math)\n'
  TRUE = T.bool\mk_const true
  FALSE = T.bool\mk_const false

  it "+ adds", ->
    with COPILOT\eval_once '(+ 1 1)'
      assert.is.true \is_const!
      assert.is.equal '<num= 2>', tostring .result

    with COPILOT\eval_once '(+ 2 3 0 1)'
      assert.is.true \is_const!
      assert.is.equal '<num= 6>', tostring .result

    with COPILOT\eval_once '
      (+ (array 1 2 3)
         (array 4 5 6))'
      assert.is.true \is_const!
      assert.is.equal '<num[3]= [5 7 9]>', tostring .result

    with COPILOT\eval_once '
        (+ (array (array 1 2) (array 3 4))
           5 5)'
      assert.is.true \is_const!
      assert.is.equal '<num[2][2]= [[11 12] [13 14]]>', tostring .result

    err = assert.has.error ->
      COPILOT\eval_once '
        (+ (array 1 2 3)
           (array 1 2))'

    err = assert.has.error ->
      COPILOT\eval_once '
        (+ (array (array 1 2) (array 1 2))
           (array 1 2))'

  it "cos", ->
    with COPILOT\eval_once '(cos pi)'
      assert.is.true \is_const!
      assert.is.equal '<num= -1.0>', tostring .result

    with COPILOT\eval_once '(cos (array 0 pi tau))'
      assert.is.true \is_const!
      assert.is.equal '<num[3]= [1.0 -1.0 1.0]>', tostring .result

  it "min", ->
    with COPILOT\eval_once '(min 0 1 2)'
      assert.is.true \is_const!
      assert.is.equal '<num= 0>', tostring .result

    with COPILOT\eval_once '(min (array 3 4) (array 5 0))'
      assert.is.true \is_const!
      assert.is.equal '<num[2]= [3 0]>', tostring .result
