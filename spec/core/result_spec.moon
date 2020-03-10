import Result, Value, Scope, SimpleRegistry from require 'core'
import Input, Op, IO from require 'core.base'
import Logger from require 'logger'
Logger.init 'silent'

op_with_inputs = (inputs) ->
  with Op!
    \setup inputs if inputs

result_with_sideinput = (value, input) ->
  with Result :value
    .side_inputs = { [value]: input }

reg = SimpleRegistry!
setup -> reg\grab!
teardown -> reg\release!

class DirtyIO extends IO
  tick: =>
  dirty: => true

describe 'Result', ->
  it 'wraps value, children', ->
    value = Value.num 3

    a = Result!
    b = Result!
    children = { a, b }

    result = Result :value, :children

    assert.is.equal value, result.value
    assert.is.same children, result.children

  it ':type gets type and assets value', ->
    result = Result value: Value.num 2
    assert.is.equal 'num', result\type!

    result = Result!
    assert.has.error -> result\type!

  it ':is_const', ->
    value = Value.num 2
    pure = Result :value
    impure = result_with_sideinput value, {}

    assert.is.true pure\is_const!
    assert.is.false impure\is_const!

    assert.is.equal value, pure\const!
    assert.has.error -> impure\const!
    assert.has.error (-> impure\const 'test'), 'test'

  it ':make_ref', ->
    value = Value.num 2
    input = Input.value value
    op = op_with_inputs { input }
    thick = Result :value, :op, children: { Result!, Result! }
    ref = thick\make_ref!

    assert ref
    assert.is.equal thick.value, ref.value
    assert.is.same thick.side_inputs, ref.side_inputs
    assert.is.same {}, ref.children
    assert.is.nil ref.op

  it 'lifts up inputs from op', ->
    event = Value 'bang', false
    event_input = Input.event event

    value = Value 'num', 4
    value_input = Input.value value

    op = op_with_inputs { event_input, value_input }
    result = Result op: op, :value

    assert.is.equal op, result.op
    assert.is.same { [event]: event_input, [value]: value_input },
                   result.side_inputs

  it 'does not lift up op inputs that are also child values', ->
    event = Value 'bang', false
    event_input = Input.event event

    value = Value 'num', 4
    value_input = Input.value value

    op = op_with_inputs { event_input, value_input }
    result = Result op: op, :value, children: { Result :value }

    assert.is.same { [event]: event_input }, result.side_inputs

  it 'lifts up side_inputs from children', ->
    event_value = Value 'bang', false
    event_input = Input.event event_value
    event = Result op: op_with_inputs { event_input }
    assert.is.same { [event_value]: event_input }, event.side_inputs

    value_value = Value 'num', 4
    value_input = Input.value value_value
    value = Result op: op_with_inputs { value_input }
    assert.is.same { [value_value]: value_input }, value.side_inputs

    result = Result children: { event, value }
    assert.is.same { [event_value]: event_input, [value_value]: value_input },
                   result.side_inputs

  describe ':tick', ->
    local a_value, a_child, a_input
    local b_value, b_child, b_input
    before_each ->
      a_value = Value 'num'
      a_input = Input.event a_value
      a_child = result_with_sideinput a_value, a_input

      b_value = Value 'num'
      b_input = Input.event b_value
      b_child = result_with_sideinput b_value, b_input

    it 'updates children when a side_input is dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      a = spy.on a_child, 'tick'
      b = spy.on b_child, 'tick'

      result = Result children: { a_child, b_child }
      result\tick!

      assert.spy(a).was_called_with match.ref a_child
      assert.spy(b).was_called_with match.ref b_child

    it 'early-outs when no side_inputs are dirty', ->
      assert.is.false a_input\dirty!
      assert.is.false b_input\dirty!

      a = spy.on a_child, 'tick'
      b = spy.on b_child, 'tick'

      result = Result children: { a_child, b_child }
      result\tick!

      assert.spy(a).was_not_called!
      assert.spy(b).was_not_called!

    it 'updates op when any op-inputs are dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = op_with_inputs a: Input.event a_value
      s = spy.on op, 'tick'

      result = Result :op, children: { a_child, b_child }
      result\tick!

      assert.spy(s).was_called_with match.ref op

    it 'early-outs when no op-inputs are dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = op_with_inputs { Input.event b_value }
      s = spy.on op, 'tick'

      result = Result :op, children: { a_child, b_child }
      result\tick!

      assert.spy(s).was_not_called!

  describe ':tick_io', ->
    it 'ticks IOs referenced in side_inputs', ->
      io = DirtyIO!
      value = Value 'an_io', io
      input = Input.io value
      op = op_with_inputs { input }
      result = Result :op

      s = spy.on io, 'tick'
      assert.is.same { [value]: input }, result.side_inputs
      result\tick_io!

      assert.spy(s).was_called_with match.ref io
