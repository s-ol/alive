import do_setup from require 'spec.test_setup'
import RTNode, Scope, SimpleRegistry from require 'alv'
import Primitive, Input, Op, Constant, EvtStream, IOStream from require 'alv.base'

setup do_setup
num = Primitive 'num'
bang = Primitive 'bang'

op_with_inputs = (inputs) ->
  with Op!
    \setup inputs if inputs

result_with_sideinput = (value, input) ->
  with RTNode :value
    .side_inputs = { [value]: input }

class DirtyIO extends IOStream
  new: => super Primitive 'dirty-io'
  dirty: => true

describe 'RTNode', ->
  it 'wraps value, children', ->
    value = Constant.num 3

    a = RTNode!
    b = RTNode!
    children = { a, b }

    result = RTNode :value, :children

    assert.is.equal value, result.value
    assert.is.same children, result.children

  it ':type gets type and assets value', ->
    result = RTNode value: Constant.num 2
    assert.is.equal num, result\type!

    result = RTNode!
    assert.has.error -> result\type!

  it ':is_const', ->
    value = Constant.num 2
    pure = RTNode :value
    impure = result_with_sideinput value, {}

    assert.is.true pure\is_const!
    assert.is.false impure\is_const!

    assert.is.equal value, pure\const!
    assert.has.error -> impure\const!
    assert.has.error (-> impure\const 'test'), 'test'

  it ':make_ref', ->
    value = Constant.num 2
    input = Input.hot value
    op = op_with_inputs { input }
    thick = RTNode :value, :op, children: { RTNode!, RTNode! }
    ref = thick\make_ref!

    assert ref
    assert.is.equal thick.value, ref.value
    assert.is.same thick.side_inputs, ref.side_inputs
    assert.is.same {}, ref.children
    assert.is.nil ref.op

  it 'lifts up inputs from op', ->
    event = Constant bang, false
    event_input = Input.hot event

    value = Constant num, 4
    value_input = Input.hot value

    op = op_with_inputs { event_input, value_input }
    result = RTNode op: op, :value

    assert.is.equal op, result.op
    assert.is.same { [event]: event_input, [value]: value_input },
                   result.side_inputs

  it 'does not lift up op inputs that are also child values', ->
    event = Constant bang, false
    event_input = Input.hot event

    value = Constant num, 4
    value_input = Input.hot value

    op = op_with_inputs { event_input, value_input }
    result = RTNode op: op, :value, children: { RTNode :value }

    assert.is.same { [event]: event_input }, result.side_inputs

  it 'lifts up side_inputs from children', ->
    event_value = Constant bang, false
    event_input = Input.hot event_value
    event = RTNode op: op_with_inputs { event_input }
    assert.is.same { [event_value]: event_input }, event.side_inputs

    value_value = Constant num, 4
    value_input = Input.hot value_value
    value = RTNode op: op_with_inputs { value_input }
    assert.is.same { [value_value]: value_input }, value.side_inputs

    result = RTNode children: { event, value }
    assert.is.same { [event_value]: event_input, [value_value]: value_input },
                   result.side_inputs

  describe ':tick', ->
    local a_value, a_child, a_input
    local b_value, b_child, b_input
    before_each ->
      a_value = EvtStream num
      a_input = Input.hot a_value
      a_child = result_with_sideinput a_value, a_input

      b_value = EvtStream num
      b_input = Input.hot b_value
      b_child = result_with_sideinput b_value, b_input

    it 'updates children when a side_input is dirty', ->
      a_value\add 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      a = spy.on a_child, 'tick'
      b = spy.on b_child, 'tick'

      result = RTNode children: { a_child, b_child }
      result\tick!

      assert.spy(a).was_called_with match.ref a_child
      assert.spy(b).was_called_with match.ref b_child

    it 'early-outs when no side_inputs are dirty', ->
      assert.is.false a_input\dirty!
      assert.is.false b_input\dirty!

      a = spy.on a_child, 'tick'
      b = spy.on b_child, 'tick'

      result = RTNode children: { a_child, b_child }
      result\tick!

      assert.spy(a).was_not_called!
      assert.spy(b).was_not_called!

    it 'updates op when any op-inputs are dirty', ->
      a_value\add 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = op_with_inputs a: Input.hot a_value
      s = spy.on op, 'tick'

      result = RTNode :op, children: { a_child, b_child }
      result\tick!

      assert.spy(s).was_called_with match.ref op

    it 'early-outs when no op-inputs are dirty', ->
      a_value\add 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = op_with_inputs { Input.hot b_value }
      s = spy.on op, 'tick'

      result = RTNode :op, children: { a_child, b_child }
      result\tick!

      assert.spy(s).was_not_called!

  describe ':poll_io', ->
    it 'polls IOs referenced in side_inputs', ->
      io = DirtyIO!
      input = Input.hot io
      op = op_with_inputs { input }
      result = RTNode :op

      s = spy.on io, 'poll'
      assert.is.same { [io]: input }, result.side_inputs
      result\poll_io!

      assert.spy(s).was_called_with match.ref io
