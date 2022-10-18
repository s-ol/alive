import TestPilot from require 'spec.test_setup'
import T, Constant, Scope from require 'alv'

describe "def", ->
  COPILOT = TestPilot!

  it "returns nothing", ->
    with COPILOT\eval_once '(def _ 3)'
      assert.is.true \is_const!
      assert.is.nil .result

  it "passes through side-effects", ->
    with COPILOT\eval_once '
        (import* time)
        (def nonconst (every 0.5 "bang!"))'
      assert.is.false \is_const!
      assert.is.nil .result
      assert.is.equal T.clock, (next .children[2].side_inputs).type

  it "validates args", ->
    err = assert.has.error -> COPILOT\eval_once '(def)'
    assert.matches "requires at least 2 arguments", err

    err = assert.has.error -> COPILOT\eval_once '(def a)'
    assert.matches "requires at least 2 arguments", err

    err = assert.has.error -> COPILOT\eval_once '(def a 1 b)'
    assert.matches "requires an even number of arguments", err

    err = assert.has.error -> COPILOT\eval_once '(def (+ 1 2) 3)'
    assert.matches "name is not a symbol", err

  it "cannot redefine symbols", ->
    err = assert.has.error -> COPILOT\eval_once '
      (def a 1
           a 2)'
    assert.matches "cannot redefine symbol", err

  it "can hide symbols", ->
    with COPILOT\eval_once '
        (def a 1)
        (do
          (def a 2)
          a)
        a'
      assert.is.true \is_const!
      assert.is.equal (Constant.num 1), .result
      assert.is.equal (Constant.num 2), .children[2].result

describe "export", ->
  COPILOT = TestPilot!

  it "returns a scope containing new defs", ->
    with COPILOT\eval_once '(export)'
      assert.is.true \is_const!
      assert.is.equal T.scope, .result.type
      assert.is.same {}, .result!.values

    with COPILOT\eval_once '(export (def a 1 b 2))'
      assert.is.true \is_const!
      assert.is.equal T.scope, .result.type
      assert.is.equal (Constant.num 1), .result!.values.a.result
      assert.is.equal (Constant.num 2), .result!.values.b.result

  it "passes through side-effects", ->
    with COPILOT\eval_once '
        (import* time)
        (export
          (def hello (every 0.5 "bang!"))
          (every 0.5 42))'
      assert.is.false \is_const!
      assert.is.equal T.scope, .result.type
      a = next .children[2].children[1].side_inputs
      b = next .children[2].children[2].side_inputs
      assert.is.truthy .side_inputs[a]
      assert.is.truthy .side_inputs[b]

  it "doesn't mutate the current scope", ->
    with COPILOT\eval_once '
      (def a 1)
      (export
        (def a 5)
        (def b 2))
      (export*)'
      assert.is.true \is_const!
      assert.is.equal T.scope, .result.type
      assert.is.equal (Constant.num 1), .result!.values.a.result
      assert.is.nil .result!.values.b

describe "export*", ->
  COPILOT = TestPilot!

  it "validates args", ->
    err = assert.has.error -> COPILOT\eval_once '(export* (+ 1 2))'
    assert.matches "arguments need to be symbols", err

    err = assert.has.error -> COPILOT\eval_once '(export* 3)'
    assert.matches "is not a sym", err

    err = assert.has.error -> COPILOT\eval_once '(export* a)'
    assert.matches "undefined symbol", err

  describe "without args", ->
    it "returns a scope containing all local defs", ->
      with COPILOT\eval_once '(export*)'
        assert.is.true \is_const!
        assert.is.equal T.scope, .result.type
        assert.is.same {}, .result!.values

      with COPILOT\eval_once '
        (def a 1 b "hello" c 3)
        (export*)'
        assert.is.true \is_const!
        assert.is.equal T.scope, .result.type
        assert.is.equal (Constant.num 1), .result!.values.a.result
        assert.is.equal (Constant.str 'hello'), .result!.values.b.result
        assert.is.equal (Constant.num 3), .result!.values.c.result

  describe "with args", ->
    it "returns a scope containing those defs", ->
      with COPILOT\eval_once '
        (def a 1 b "hello" c 3)
        (export* a b)'
        assert.is.true \is_const!
        assert.is.equal T.scope, .result.type
        assert.is.equal (Constant.num 1), .result!.values.a.result
        assert.is.equal (Constant.str 'hello'), .result!.values.b.result
        assert.is.nil .result!.values.c

describe "use", ->
  COPILOT = TestPilot!

  it "returns nothing", ->
    with COPILOT\eval_once '(use (export))'
      assert.is.true \is_const!
      assert.is.nil .result

  it "updates the current scope", ->
    with COPILOT\eval_once '
      (use (export
        (def a 2)))
      a'
      assert.is.true \is_const!
      assert.is.equal (Constant.num 2), .result

  it "terms and conditions apply", ->
    err = assert.has.error -> COPILOT\eval_once '
      (def a 1)
      (use
        (export
          (def a 5)
          (def b 2)))'
    assert.matches "cannot redefine symbol", err
