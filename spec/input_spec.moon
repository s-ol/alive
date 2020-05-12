import do_setup, do_teardown from require 'spec.test_setup'
import Input, T, Result, IOStream from require 'alv.base'

setup do_setup
teardown do_teardown

class MyIO extends IOStream
  new: => super T.my_io
  dirty: => @is_dirty

basic_tests = (result, input) ->
  it 'gives access to the Result', ->
    assert.is.equal result, input.result

  it 'forwards :unwrap', ->
    assert.is.equal result\unwrap!, input\unwrap!, nil
    assert.is.equal result\unwrap!, input!, nil

  it 'gives access to the type string', ->
    assert.is.equal result.type, input\type!

  it 'gives access to the metatype string', ->
    assert.is.equal result.metatype, input\metatype!

describe 'Input.cold', ->
  result = T.num\mk_sig 1
  input = Input.cold result

  basic_tests result, input

  it 'is marked cold', ->
    assert.is.equal 'cold', input.mode

  it 'is never dirty', ->
    assert.is.false input\dirty!
    result\set 2
    assert.is.false input\dirty!

    input\setup nil
    assert.is.false input\dirty!
    input\finish_setup!

    new_input = Input.cold T.num\mk_sig 3
    new_input\setup input
    assert.is.false new_input\dirty!
    new_input.result\set 4
    assert.is.false new_input\dirty!
    input\finish_setup!

describe 'Input.hot', ->
  describe 'with Constant', ->
    result = T.num\mk_const 1
    input = Input.hot result

    basic_tests result, input

    it 'is marked cold', ->
      assert.is.equal 'cold', input.mode

    describe 'at evaltime', ->
      it 'is dirty when new', ->
        assert.is.false result\dirty!

        newinput = Input.hot result
        newinput\setup nil
        assert.is.true newinput\dirty!
        newinput\finish_setup!

      it 'is dirty when different', ->
        newval = T.num\mk_const 2

        assert.is.false newval\dirty!
        newinput = Input.hot newval
        newinput\setup input
        assert.is.true newinput\dirty!
        newinput\finish_setup!

      it 'is not dirty when equal', ->
        newval = T.num\mk_const 1

        assert.is.false newval\dirty!
        newinput = Input.hot newval
        newinput\setup input
        assert.is.false newinput\dirty!
        newinput\finish_setup!

  describe 'with EvtStream', ->
    result = T.num\mk_evt!
    input = Input.hot result

    basic_tests result, input

    it 'is marked hot', ->
      assert.is.equal 'hot', input.mode

    it 'is dirty when the EvtStream is dirty', ->
      assert.is.false input\dirty!
      assert.is.false result\dirty!

      input\setup nil
      assert.is.false input\dirty!
      input\finish_setup!

      COPILOT\next_tick!
      result\set 1

      assert.is.true input\dirty!
      assert.is.true result\dirty!

      input\setup nil
      assert.is.true input\dirty!
      input\finish_setup!

      assert.is.true input\dirty!
      assert.is.true result\dirty!

  describe 'with IOStream', ->
    result = MyIO!
    input = Input.hot result

    basic_tests result, input

    it 'is marked for lifting', ->
      assert.is.equal 'io', input.mode

    it 'is dirty when the IOStream is dirty', ->
      result.is_dirty = false

      assert.is.false input\dirty!
      assert.is.false result\dirty!

      input\setup nil
      assert.is.false input\dirty!
      input\finish_setup!

      COPILOT\next_tick!
      result.is_dirty = true

      assert.is.true input\dirty!
      assert.is.true result\dirty!

      input\setup nil
      assert.is.true input\dirty!
      input\finish_setup!

      assert.is.true input\dirty!
      assert.is.true result\dirty!

  describe 'with SigStream', ->
    result = T.num\mk_sig 1
    local input

    describe 'at evaltime', ->
      it 'is dirty when new', ->
        assert.is.false result\dirty!

        input = Input.hot result
        input\setup nil
        assert.is.true input\dirty!
        input\finish_setup!

      it 'is dirty when different', ->
        newval = T.num\mk_sig 2

        assert.is.false newval\dirty!
        newinput = Input.hot newval
        newinput\setup input
        assert.is.true newinput\dirty!
        newinput\finish_setup!

      it 'is not dirty when equal', ->
        newval = T.num\mk_sig!
        newval\set 1

        assert.is.true newval\dirty!
        newinput = Input.hot newval
        newinput\setup input
        assert.is.false newinput\dirty!
        newinput\finish_setup!

    it 'is marked hot', ->
      assert.is.equal 'hot', input.mode

    describe 'at runtime', ->
      it 'is dirty when the result is dirty', ->
        result\set 3
        assert.is.true result\dirty!
        assert.is.true input\dirty!

        COPILOT\next_tick!
        assert.is.false result\dirty!
        assert.is.false input\dirty!
