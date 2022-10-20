import TestPilot from require 'spec.test_setup'
import T, Array, Constant from require 'alv'

describe "logic", ->
  test = TestPilot '', '(import* testing logic)\n'
  TRUE = T.bool\mk_const true
  FALSE = T.bool\mk_const false

  describe "==", ->
    it "can compare any type", ->
      with COPILOT\eval_once '(== 1 1)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(== 1 2)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(== 1 "hello")'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(== "hello" "hello")'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(== (array 1 2 3) (array 1 2 3))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(== (array 1 2 3) (array 1 2 1))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(== (array 1 2 3) (array 1 2))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(== (array 1 2 3) (array 1 2 3 4))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(==
          (struct "a" 1 "b" true "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(==
          (struct "a" 1 "b" false "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(==
          (struct "a" 1 "b" true "c" (array "test" "toast"))
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(==
          (struct "a" 1 "b" true)
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(==
          (struct "a" 1 "b" true)
          (struct "a" 1))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(== print print)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(== print ==)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

    it "is aliased as eq", ->
      with COPILOT\eval_once '(== eq ==)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

  describe "!=", ->
    it "can compare any type", ->
      with COPILOT\eval_once '(!= 1 1)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(!= 1 2)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!= 1 "hello")'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!= "hello" "hello")'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(!= (array 1 2 3) (array 1 2 3))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(!= (array 1 2 3) (array 1 2 1))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!= (array 1 2 3) (array 1 2))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!= (array 1 2 3) (array 1 2 3 4))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!=
          (struct "a" 1 "b" true "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(!=
          (struct "a" 1 "b" false "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!=
          (struct "a" 1 "b" true "c" (array "test" "toast"))
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!=
          (struct "a" 1 "b" true)
          (struct "a" 1 "b" true "c" (array "test")))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!=
          (struct "a" 1 "b" true)
          (struct "a" 1))'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(!= print print)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(!= print ==)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

    it "is aliased as note-eq", ->
      with COPILOT\eval_once '(== not-eq !=)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

  describe "bool", ->
    it "coerces numbers", ->
      with COPILOT\eval_once '(bool 0)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(bool 1)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(bool -1)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(bool 1024)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

    it "accepts booleans", ->
      with COPILOT\eval_once '(bool false)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(bool true)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

  describe "not", ->
    it "accepts booleans", ->
      with COPILOT\eval_once '(not false)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(not true)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

    it "coerces numbers", ->
      with COPILOT\eval_once '(not 0)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(not 1)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(not -1)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(not 1024)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result


  describe "or", ->
    it "accepts any number of mixed arguments", ->
      with COPILOT\eval_once '(or false 0)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(or 1 0)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(or 0 false 0 0 0 0)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(or 0 0 0 true 0 0)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(or 0 true 0 1 0 0)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

  describe "and", ->
    it "accepts any number of mixed arguments", ->
      with COPILOT\eval_once '(and false 1)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(and 1 true)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(and false 0)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(and 1 1 true 0)'
        assert.is.true \is_const!
        assert.is.equal FALSE, .result

      with COPILOT\eval_once '(and 1 1 true true 1)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

      with COPILOT\eval_once '(and 1 1 1)'
        assert.is.true \is_const!
        assert.is.equal TRUE, .result

  describe "<", ->
    it "is aliased as asc?", -> COPILOT\eval_once '
      (expect= < asc?)
    '

    it "compares numbers as expected", -> COPILOT\eval_once '
      (assert (< -2 5))
      (assert (not (< 3 1)))
      (assert (not (< 1 1)))
    '

    it "can handle multiple arguments", -> COPILOT\eval_once '
      (assert (< 1 2 3))
      (assert (not (< 2 3.5 3 4)))
      (assert (not (< 3 2 1)))
    '

  describe "<=", ->
    it "compares numbers as expected", -> COPILOT\eval_once '
      (assert (<= 1 1))
      (assert (<= -2 2))
      (assert (not (<= 3 2)))
    '

    it "can handle multiple arguments", -> COPILOT\eval_once '
      (assert (<= 1 2 3))
      (assert (<= 1 2 2 3))
      (assert (not (<= 2 3 2.5 4)))
      (assert (not (<= 3 2 2 1)))
    '

  describe ">", ->
    it "is aliased as desc?", -> COPILOT\eval_once '
      (expect= > desc?)
    '

    it "compares numbers as expected", -> COPILOT\eval_once '
      (assert (> 3 1))
      (assert (not (> -2 5)))
      (assert (not (> 1 1)))
    '

    it "can handle multiple arguments", -> COPILOT\eval_once '
      (assert (> 3 2 1))
      (assert (not (> 5 4 3 3.5 2)))
      (assert (not (> 1 2 3)))
    '

  describe ">=", ->
    it "compares numbers as expected", -> COPILOT\eval_once '
      (assert (>= 1 1))
      (assert (>= 5 1))
      (assert (not (>= 2 3)))
    '

    it "can handle multiple arguments", -> COPILOT\eval_once '
      (assert (>= 3 2 1))
      (assert (>= 3 2 2 1))
      (assert (not (>= 5 4 3 3 3.5 2)))
      (assert (not (>= 1 2 2 3)))
    '

  describe "<, <=, >, >=", ->
    each = (fn) ->
      fn '<'
      fn '<='
      fn '>'
      fn '>='

    it "need at least two arguments", ->
      each =>
        err = assert.has.error -> COPILOT\eval_once "(#{@})"
        assert.matches "couldn't match arguments", err

        err = assert.has.error -> COPILOT\eval_once "(#{@} 1)"
        assert.matches "couldn't match arguments", err

    it "only work on numbers", ->
      each =>
        err = assert.has.error -> COPILOT\eval_once "(#{@} 1 'b')"
        assert.matches "couldn't match arguments", err

        err = assert.has.error -> COPILOT\eval_once "(#{@} 'c' 'd')"
        assert.matches "couldn't match arguments", err

        err = assert.has.error -> COPILOT\eval_once "(#{@} true 3)"
        assert.matches "couldn't match arguments", err
