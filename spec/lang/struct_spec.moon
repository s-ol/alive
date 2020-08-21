import TestPilot from require 'spec.test_setup'
import T, Struct, Constant from require 'alv'

describe "struct", ->
  test = TestPilot '', '(import* struct)\n'

  ab = Struct { a: T.num, b: T.bool }

  describe "(set)", ->
    it "can update values", ->
      rt = COPILOT\eval_once '(set (struct "a" 1 "b" false) "a" 2)'
      assert.is.true rt\is_const!
      assert.is.equal ab\mk_const({ a: 2, b: false }), rt.result

    it "cannot add members", ->
      err = assert.has.error -> COPILOT\eval_once '(set (struct "a" 1) "b" 2)'
      assert.matches "{a: num} has no 'b' key", err

    it "checks value type", ->
      err = assert.has.error -> COPILOT\eval_once '(set (struct "a" 1) "a" "str")'
      assert.matches "expected value for key 'a' to be num, not str", err

  describe "(get)", ->
    it "can get values", ->
      rt = COPILOT\eval_once '(get (struct "a" 1 "b" false) "a")'
      assert.is.true rt\is_const!
      assert.is.equal (Constant.num 1), rt.result

    it "checks keys", ->
      err = assert.has.error -> COPILOT\eval_once '(get (struct "a" 1) "b")'
      assert.matches "has no 'b' key", err

  describe "(insert)", ->
    it "can add members", ->
      rt = COPILOT\eval_once '(insert (struct "b" true) "a" 1)'
      assert.is.true rt\is_const!
      assert.is.equal ab\mk_const({ a: 1, b: true }), rt.result

    it "doesn't clobber existing members", ->
      err = assert.has.error -> COPILOT\eval_once '(insert (struct "a" 1) "a" 2)'
      assert.matches "key 'a' already exists in value of type {a: num}", err

  describe "(remove)", ->
    it "can remove members", ->
      rt = COPILOT\eval_once '(remove (struct "a" 1 "b" false "c" "abc") "c")'
      assert.is.true rt\is_const!
      assert.is.equal ab\mk_const({ a: 1, b: false }), rt.result

    it "checks keys", ->
      err = assert.has.error -> COPILOT\eval_once '(remove (struct "a" 1) "b")'
      assert.matches "has no 'b' key", err
