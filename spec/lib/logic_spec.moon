import TestPilot from require 'spec.test_setup'

describe "logic", ->
  test = TestPilot '', '(import* testing logic)\n'

  describe "==", ->
    it "can compare any type", -> COPILOT\eval_once '
      (expect= true (== 1 1))
      (expect= false (== 1 2))
      (expect= false (== 1 "hello"))
      (expect= true (== "hello" "hello"))
      (expect= true (== (array 1 2 3) (array 1 2 3)))
      (expect= false (== (array 1 2 3) (array 1 2 1)))
      (expect= false (== (array 1 2 3) (array 1 2)))
      (expect= false (== (array 1 2 3) (array 1 2 3 4)))
      (expect= true (==
          (struct "a" 1 "b" true "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= false (==
          (struct "a" 1 "b" false "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= false (==
          (struct "a" 1 "b" true "c" (array "test" "toast"))
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= false (==
          (struct "a" 1 "b" true)
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= false (==
          (struct "a" 1 "b" true)
          (struct "a" 1)))
      (expect= true (== print print))
      (expect= false (== print ==))
    '

    it "is aliased as eq", -> COPILOT\eval_once '
      (expect= true (== eq ==))
    '

  describe "!=", ->
    it "can compare any type", -> COPILOT\eval_once '
      (expect= false (!= 1 1))
      (expect= true (!= 1 2))
      (expect= true (!= 1 "hello"))
      (expect= false (!= "hello" "hello"))
      (expect= false (!= (array 1 2 3) (array 1 2 3)))
      (expect= true (!= (array 1 2 3) (array 1 2 1)))
      (expect= true (!= (array 1 2 3) (array 1 2)))
      (expect= true (!= (array 1 2 3) (array 1 2 3 4)))
      (expect= false (!=
          (struct "a" 1 "b" true "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= true (!=
          (struct "a" 1 "b" false "c" (array "test"))
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= true (!=
          (struct "a" 1 "b" true "c" (array "test" "toast"))
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= true (!=
          (struct "a" 1 "b" true)
          (struct "a" 1 "b" true "c" (array "test"))))
      (expect= true (!=
          (struct "a" 1 "b" true)
          (struct "a" 1)))
      (expect= false (!= print print))
      (expect= true (!= print ==))
    '

    it "is aliased as not-eq", -> COPILOT\eval_once '
      (expect= true (== not-eq !=))
    '

  describe "bool", ->
    it "coerces numbers", -> COPILOT\eval_once '
      (expect= false (bool 0))
      (expect= true (bool 1))
      (expect= true (bool -1))
      (expect= true (bool 1024))
    '

    it "accepts booleans", -> COPILOT\eval_once '
      (expect= false (bool false))
      (expect= true (bool true))
    '

  describe "not", ->
    it "accepts booleans", -> COPILOT\eval_once '
      (expect= true (not false))
      (expect= false (not true))
    '

    it "coerces numbers", -> COPILOT\eval_once '
      (expect= true (not 0))
      (expect= false (not 1))
      (expect= false (not -1))
      (expect= false (not 1024))
    '

  describe "or", ->
    it "accepts any number of mixed arguments", -> COPILOT\eval_once '
      (expect= false (or false 0))
      (expect= true (or 1 0))
      (expect= false (or 0 false 0 0 0 0))
      (expect= true (or 0 0 0 true 0 0))
      (expect= true (or 0 true 0 1 0 0))
    '

  describe "and", ->
    it "accepts any number of mixed arguments", -> COPILOT\eval_once '
      (expect= false (and false 1))
      (expect= true (and 1 true))
      (expect= false (and false 0))
      (expect= false (and 1 1 true 0))
      (expect= true (and 1 1 true true 1))
      (expect= true (and 1 1 1))
    '

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
