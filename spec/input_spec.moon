import Input, Result, ValueStream, EventStream, IOStream from require 'alv.base'
import SimpleRegistry from require 'alv'
import Logger from require 'alv.logger'
Logger.init 'silent'

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

class MyIO extends IOStream
  new: => super 'my-io'
  dirty: => @is_dirty

basic_tests = (stream, input) ->
  it 'gives access to the Stream', ->
    assert.is.equal stream, input.stream

  it 'forwards :unwrap', ->
    assert.is.same stream\unwrap!, input\unwrap!
    assert.is.same stream\unwrap!, input!

  it 'gives access to the type string', ->
    assert.is.equal stream.type, input\type!

  it 'gives access to the metatype string', ->
    assert.is.equal stream.metatype, input\metatype!

describe 'Input.cold', ->
  stream = ValueStream.num 1
  input = Input.cold stream

  basic_tests stream, input

  it 'is never dirty', ->
    assert.is.false input\dirty!
    stream\set 2
    assert.is.false input\dirty!

    input\setup nil
    assert.is.false input\dirty!
    input\finish_setup!

    new_input = Input.cold ValueStream.num 3
    new_input\setup input
    assert.is.false new_input\dirty!
    new_input.stream\set 4
    assert.is.false new_input\dirty!
    input\finish_setup!

describe 'Input.hot', ->
  describe 'with EventStream', ->
    stream = EventStream 'num'
    input = Input.hot stream

    basic_tests stream, input

    it 'is marked for lifting', ->
      assert.is.nil input.io

    it 'is dirty when the EventStream is dirty', ->
      assert.is.false input\dirty!
      assert.is.false stream\dirty!

      input\setup nil
      assert.is.false input\dirty!
      input\finish_setup!

      reg\next_tick!
      stream\add 1

      assert.is.true input\dirty!
      assert.is.true stream\dirty!

      input\setup nil
      assert.is.true input\dirty!
      input\finish_setup!

      assert.is.true input\dirty!
      assert.is.true stream\dirty!

  describe 'with IOStream', ->
    stream = MyIO!
    input = Input.hot stream

    basic_tests stream, input

    it 'is marked for lifting', ->
      assert.is.true input.io

    it 'is dirty when the IOStream is dirty', ->
      stream.is_dirty = false

      assert.is.false input\dirty!
      assert.is.false stream\dirty!

      input\setup nil
      assert.is.false input\dirty!
      input\finish_setup!

      reg\next_tick!
      stream.is_dirty = true

      assert.is.true input\dirty!
      assert.is.true stream\dirty!

      input\setup nil
      assert.is.true input\dirty!
      input\finish_setup!

      assert.is.true input\dirty!
      assert.is.true stream\dirty!

  describe 'with ValueStream', ->
    stream = ValueStream.num 1
    local input

    describe 'at evaltime', ->
      it 'is dirty when new', ->
        assert.is.false stream\dirty!

        input = Input.hot stream
        input\setup nil
        assert.is.true input\dirty!
        input\finish_setup!

      it 'is dirty when different', ->
        newval = ValueStream.num 2

        assert.is.false newval\dirty!
        newinput = Input.hot newval
        newinput\setup input
        assert.is.true newinput\dirty!
        newinput\finish_setup!

      it 'is not dirty when equal', ->
        newval = ValueStream.num 1
        newval\set 1

        assert.is.true newval\dirty!
        newinput = Input.hot newval
        newinput\setup input
        assert.is.false newinput\dirty!
        newinput\finish_setup!

    describe 'at runtime', ->
      it 'is dirty when the stream is dirty', ->
        stream\set 3
        assert.is.true stream\dirty!
        assert.is.true input\dirty!

        reg\next_tick!
        assert.is.false stream\dirty!
        assert.is.false input\dirty!
