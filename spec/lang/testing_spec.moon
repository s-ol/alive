import TestPilot from require 'spec.test_setup'
import T, Array, Constant from require 'alv'

describe "testing", ->
  test = TestPilot '', '(import* testing logic)\n'

  describe "assert", ->
    it "ignores true", ->
      with COPILOT\eval_once '(assert true)'
        assert.is.true \is_const!
        assert.is.nil .result

      with COPILOT\eval_once '(assert true "with message")'
        assert.is.true \is_const!
        assert.is.nil .result

    it "throws on false", ->
      assert.has.error -> COPILOT\eval_once '(assert false)'

    it "shows failing expression", ->
      err = assert.has.error -> COPILOT\eval_once '(assert false)'
      assert.matches "assertion failed: false", err

      err = assert.has.error -> COPILOT\eval_once '(assert (== 1 2))'
      assert.matches "assertion failed: %(== 1 2%)", err

    it "supports custom error messages", ->
      err = assert.has.error -> COPILOT\eval_once '(assert (== "green" "red") "duck isnt green")'
      assert.matches "duck isnt green", err

  describe "expect=", ->
    it "passes equal params", ->
      with COPILOT\eval_once '(expect= 1 1 1)'
        assert.is.true \is_const!
        assert.is.nil .result

      with COPILOT\eval_once '(expect= 2 2 2)'
        assert.is.true \is_const!
        assert.is.nil .result

      with COPILOT\eval_once '(expect= true true)'
        assert.is.true \is_const!
        assert.is.nil .result

      with COPILOT\eval_once '(expect= "hello" "hello")'
        assert.is.true \is_const!
        assert.is.nil .result

      with COPILOT\eval_once '(expect= (array 1 2) (array 1 2))'
        assert.is.true \is_const!
        assert.is.nil .result

    it "fails different values", ->
      assert.has.error -> COPILOT\eval_once '(expect= 1 2)'
      assert.has.error -> COPILOT\eval_once '(expect= 1 1 2)'
      assert.has.error -> COPILOT\eval_once '(expect= 2 1 1)'

      assert.has.error -> COPILOT\eval_once '(expect= true false)'

      assert.has.error -> COPILOT\eval_once '(expect= "asdf" "bsdf")'
      assert.has.error -> COPILOT\eval_once '(expect= (array 1 2) (array 1 3))'

    it "fails different types", ->
      assert.has.error -> COPILOT\eval_once '(expect= true 2)'
      assert.has.error -> COPILOT\eval_once '(expect= true true 1)'
      assert.has.error -> COPILOT\eval_once '(expect= true false "str")'

    it "reports first failing arguments", ->
      err = assert.has.error -> COPILOT\eval_once '(expect= 1 2)'
      assert.matches "assertion error: Expected 2 to equal <num= 1> %(got <num= 2>%)", err

      err = assert.has.error -> COPILOT\eval_once '(expect= 1 1 2 4)'
      assert.matches "assertion error: Expected 2 to equal <num= 1> %(got <num= 2>%)", err

      err = assert.has.error -> COPILOT\eval_once '(expect= true 2 3)'
      assert.matches "assertion error: Expected 2 to equal <bool= true> %(got <num= 2>%)", err

    it "reports full expressions", ->
      err = assert.has.error -> COPILOT\eval_once '(import* math) (expect= 1 (+ 1 1))'
      assert.matches "assertion error: Expected %(%+ 1 1%) to equal <num= 1> %(got <num= 2>%)", err
