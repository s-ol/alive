import TestPilot from require 'spec.test_setup'
import T, Array, Constant from require 'alv'

describe "array", ->
  test = TestPilot '', '(import* array-)\n'

  svec3 = Array 3, T.str

  it "can contain any type", ->
    COPILOT\eval_once '(array 1 2 3)'
    COPILOT\eval_once '(array true false)'
    COPILOT\eval_once '(array "a")'
    COPILOT\eval_once '(array (array 1 2) (array 3 4))'

  it "cannot contain mixed types", ->
    err = assert.has.error -> COPILOT\eval_once '(array 1 false)'
    assert.matches "argument error: couldn't match arguments", err

  describe "(set)", ->
    it "can swap values", ->
      rt = COPILOT\eval_once '(set (array "f" "b" "c") 0 "a")'
      assert.is.true rt\is_const!
      assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

    it "checks value type", ->
      err = assert.has.error -> COPILOT\eval_once '(set (array 1) 0 "a")'
      assert.matches "expected value of type num, not str", err

    it "checks index range", ->
      err = assert.has.error -> COPILOT\eval_once '(set (array 1 2) -1 0)'
      assert.matches "index '%-1' out of range!", err

      COPILOT\eval_once '(set (array 1 2) 0 0)'

      COPILOT\eval_once '(set (array 1 2) 1 0)'

      err = assert.has.error -> COPILOT\eval_once '(set (array 1 2) 2 0)'
      assert.matches "index '2' out of range!", err

  describe "(get)", ->
    it "can get a value", ->
      rt = COPILOT\eval_once '(get (array 1 2) 0)'
      assert.is.true rt\is_const!
      assert.is.equal (Constant.num 1), rt.result

    it "checks index range", ->
      err = assert.has.error -> COPILOT\eval_once '(get (array 1 2) -1)'
      assert.matches "index '%-1' out of range!", err

      COPILOT\eval_once '(get (array 1 2) 0)'

      COPILOT\eval_once '(get (array 1 2) 1)'

      err = assert.has.error -> COPILOT\eval_once '(get (array 1 2) 2)'
      assert.matches "index '2' out of range!", err

  describe '(head)', ->
    it "can peek a value", ->
      rt = COPILOT\eval_once '(head (array 1 2))'
      assert.is.true rt\is_const!
      assert.is.equal (Constant.num 1), rt.result

  describe '(tail)', ->
    it "gets rest of an array", ->
      rt = COPILOT\eval_once '(tail (array 1))'
      assert.is.true rt\is_const!
      assert.is.same (Array 0, T.num), rt.result.type
      assert.is.same {}, rt.result!

      rt = COPILOT\eval_once '(tail (array 1 2))'
      assert.is.true rt\is_const!
      assert.is.same (Array 1, T.num), rt.result.type
      assert.is.same { 2 }, rt.result!

      rt = COPILOT\eval_once '(tail (array 1 2 3 4))'
      assert.is.true rt\is_const!
      assert.is.same (Array 3, T.num), rt.result.type
      assert.is.same { 2, 3, 4 }, rt.result!

  describe '(prepend)', ->
    it "prepends to array", ->
      rt = COPILOT\eval_once '(prepend (array 2) 1)'
      assert.is.true rt\is_const!
      assert.is.same (Array 2, T.num), rt.result.type
      assert.is.same { 1, 2 }, rt.result!

      rt = COPILOT\eval_once '(prepend (array 2 3 4) 1)'
      assert.is.true rt\is_const!
      assert.is.same (Array 4, T.num), rt.result.type
      assert.is.same { 1, 2, 3, 4 }, rt.result!

  describe "(insert)", ->
    it "can insert a value", ->
      rt = COPILOT\eval_once '(insert (array "b" "c") 0 "a")'
      assert.is.true rt\is_const!
      assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

      rt = COPILOT\eval_once '(insert (array "a" "c") 1 "b")'
      assert.is.true rt\is_const!
      assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

      rt = COPILOT\eval_once '(insert (array "a" "b") 2 "c")'
      assert.is.true rt\is_const!
      assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

    it "checks index range", ->
      err = assert.has.error -> COPILOT\eval_once '(insert (array 1 2) -1 0)'
      assert.matches "index '%-1' out of range!", err

      COPILOT\eval_once '(insert (array 1 2) 0 0)'

      COPILOT\eval_once '(insert (array 1 2) 1 0)'

      COPILOT\eval_once '(insert (array 1 2) 2 0)'

      err = assert.has.error -> COPILOT\eval_once '(insert (array 1 2) 3 0)'
      assert.matches "index '3' out of range!", err

  describe "(remove)", ->
    it "can remove a value", ->
      rt = COPILOT\eval_once '(remove (array "d" "a" "b" "c") 0)'
      assert.is.true rt\is_const!
      assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

      rt = COPILOT\eval_once '(remove (array "a" "b" "c" "d") 3)'
      assert.is.true rt\is_const!
      assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

    it "checks index range", ->
      err = assert.has.error -> COPILOT\eval_once '(remove (array 1 2 3) -1)'
      assert.matches "index '%-1' out of range!", err

      err = assert.has.error -> COPILOT\eval_once '(remove (array 1 2 3) 3)'
      assert.matches "index '3' out of range!", err

  it "can be concatenated with (concat)", ->
    rt = COPILOT\eval_once '(concat (array "a" "b") (array "c"))'
    assert.is.true rt\is_const!
    assert.is.equal svec3\mk_const({ 'a', 'b', 'c' }), rt.result

  it "size can be read using (size)", ->
    rt = COPILOT\eval_once '(size (array 1))'
    assert.is.true rt\is_const!
    assert.is.equal (Constant.num 1), rt.result

    rt = COPILOT\eval_once '(size (array 1 2 3))'
    assert.is.true rt\is_const!
    assert.is.equal (Constant.num 3), rt.result
