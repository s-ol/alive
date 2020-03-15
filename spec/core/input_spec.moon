import Input, Result, Value, IO from require 'core.base'
import SimpleRegistry from require 'core'
import Logger from require 'logger'
Logger.init 'silent'

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

describe 'Input.event', ->
  val = Value.num 1
  input = Input.event val

  describe 'at evaltime', ->
    it 'follows Value when new', ->
      input\setup nil
    
      val\set 2
      assert.is.true val\dirty!
      assert.is.true input\dirty!

      reg\next_tick!
      assert.is.false val\dirty!
      assert.is.false input\dirty!

      input\finish_setup!

    it 'follows Value when different', ->
      new_input = Input.event Value.num 3
      new_input\setup input

      assert.is.false new_input.stream\dirty!
      assert.is.false new_input\dirty!
    
      new_input.stream\set 3
      assert.is.true new_input.stream\dirty!
      assert.is.true new_input\dirty!

      reg\next_tick!
      new_input\finish_setup!

    it 'follows Value when equal', ->
      new_input = Input.event Value.num 2
      new_input\setup input

      assert.is.false new_input.stream\dirty!
      assert.is.false new_input\dirty!
    
      new_input.stream\set 2
      assert.is.true new_input.stream\dirty!
      assert.is.true new_input\dirty!

  describe 'at runtime', ->
    it 'is dirty when the value is dirty', ->
      val\set 3
      assert.is.true val\dirty!
      assert.is.true input\dirty!

      reg\next_tick!
      assert.is.false val\dirty!
      assert.is.false input\dirty!

  it 'unwraps to the lua value', ->
    assert.is.equal 3, input\unwrap!
    assert.is.equal 3, input!

  it 'gives access to the type string', ->
    assert.is.equal 'num', input\type!

  it 'gives access to the Value', ->
    assert.is.equal val, input.stream

describe 'Input.value', ->
  val = Value.num 1
  local input

  describe 'at evaltime', ->
    it 'is dirty when new', ->
      assert.is.false val\dirty!

      input = Input.value val
      input\setup nil
      assert.is.true input\dirty!
      input\finish_setup!

    it 'is dirty when different', ->
      newval = Value.num 2

      assert.is.false newval\dirty!
      newinput = Input.value newval
      newinput\setup input
      assert.is.true newinput\dirty!
      newinput\finish_setup!

    it 'is not dirty when equal', ->
      newval = Value.num 1
      newval\set 1

      assert.is.true newval\dirty!
      newinput = Input.value newval
      newinput\setup input
      assert.is.false newinput\dirty!
      newinput\finish_setup!

  describe 'at runtime', ->
    it 'is dirty when the value is dirty', ->
      val\set 3
      assert.is.true val\dirty!
      assert.is.true input\dirty!

      reg\next_tick!
      assert.is.false val\dirty!
      assert.is.false input\dirty!

  it 'unwraps to the lua value', ->
    assert.is.equal 3, input\unwrap!
    assert.is.equal 3, input!

  it 'gives access to the type string', ->
    assert.is.equal 'num', input\type!

  it 'gives access to the Value', ->
    assert.is.equal val, input.stream

describe 'Input.cold', ->
  val = Value.num 1
  input = Input.cold val

  it 'is never dirty', ->
    assert.is.false input\dirty!
    val\set 2
    assert.is.false input\dirty!

    input\setup nil
    assert.is.false input\dirty!
    input\finish_setup!

    new_input = Input.cold Value.num 3
    new_input\setup input
    assert.is.false new_input\dirty!
    new_input.stream\set 4
    assert.is.false new_input\dirty!
    input\finish_setup!

  it 'unwraps to the lua value', ->
    assert.is.equal 2, input\unwrap!
    assert.is.equal 2, input!

  it 'gives access to the type string', ->
    assert.is.equal 'num', input\type!

  it 'gives access to the Value', ->
    assert.is.equal val, input.stream

class MyIO extends IO
  dirty: => @is_dirty

describe 'Input.io', ->
  io = MyIO!
  val = Value 'test-io', io
  input = Input.io val

  it 'is dirty when the IO is dirty', ->
    io.is_dirty = false

    assert.is.false val\dirty!
    assert.is.false input\dirty!
    assert.is.false io\dirty!

    input\setup nil
    assert.is.false input\dirty!
    input\finish_setup!

    val\set io
    assert.is.true val\dirty!
    assert.is.false input\dirty!
    assert.is.false io\dirty!

    reg\next_tick!

    io.is_dirty = true

    assert.is.false val\dirty!
    assert.is.true input\dirty!
    assert.is.true io\dirty!

    input\setup nil
    assert.is.true input\dirty!
    input\finish_setup!

    val\set io
    assert.is.true val\dirty!
    assert.is.true input\dirty!
    assert.is.true io\dirty!

  it 'unwraps to the io value', ->
    assert.is.equal io, input\unwrap!
    assert.is.equal io, input!

  it 'gives access to the type string', ->
    assert.is.equal 'test-io', input\type!

  it 'gives access to the Value', ->
    assert.is.equal val, input.stream
