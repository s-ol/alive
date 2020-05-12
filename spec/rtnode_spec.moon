import do_setup from require 'spec.test_setup'
import RTNode, Scope, SimpleRegistry from require 'alv'
import T, Input, Op, Constant, IOStream from require 'alv.base'

setup do_setup

class DirtyIO extends IOStream
  new: => super T.dirty_io
  dirty: => true

op_with_inputs = (inputs) ->
  with Op!
    \setup inputs if inputs

dirty_op = ->
  result = DirtyIO!
  input = Input.hot result
  result, input, op_with_inputs { input }

node_with_sideinput = (result, input) ->
  with RTNode :result
    .side_inputs = { [result]: input }

describe 'RTNode', ->
  it 'wraps result, children', ->
    result = Constant.num 3

    a = RTNode!
    b = RTNode!
    children = { a, b }

    node = RTNode :result, :children

    assert.is.equal result, node.result
    assert.is.same children, node.children

  it ':type gets type and assets value', ->
    node = RTNode result: Constant.num 2
    assert.is.equal T.num, node\type!

    node = RTNode!
    assert.has.error -> node\type!

  it ':is_const', ->
    result = Constant.num 2
    pure = RTNode :result
    impure = node_with_sideinput result, {}

    assert.is.true pure\is_const!
    assert.is.false impure\is_const!

    assert.is.equal result, pure\const!
    assert.has.error -> impure\const!
    assert.has.error (-> impure\const 'test'), 'test'

  it ':make_ref', ->
    result = T.num\mk_sig 2
    input = Input.hot result
    op = op_with_inputs { input }
    thick = RTNode :result, :op, children: { RTNode!, RTNode! }
    ref = thick\make_ref!

    assert ref
    assert.is.equal thick.result, ref.result
    assert.is.same thick.side_inputs, ref.side_inputs
    assert.is.same {}, ref.children
    assert.is.nil ref.op

  it 'lifts up inputs from op', ->
    event = T.bang\mk_evt!
    event_input = Input.hot event

    value = T.num\mk_sig 4
    value_input = Input.hot value

    op = op_with_inputs { event_input, value_input }
    node = RTNode :op, result: value

    assert.is.equal op, node.op
    assert.is.same { [event]: event_input, [value]: value_input },
                   node.side_inputs

  it 'does not lift up op inputs that are also children', ->
    child_result, child_input, child_op = dirty_op!
    result = T.num\mk_sig 4
    child = RTNode op: child_op, :result

    event = T.bang\mk_evt!
    event_input = Input.hot event
    input = Input.hot child

    op = op_with_inputs { event_input, input }
    node = RTNode :op, children: { child }

    assert.is.same { [event]: event_input, [child_result]: child_input },
                   node.side_inputs

  it 'does not lift up op inputs that are cold', ->
    bang = T.bang\mk_const true
    bang_input = Input.hot bang

    num = T.num\mk_const 2
    num_input = Input.cold num

    sym = T.sym\mk_sig 'hello'
    sym_input = Input.hot sym

    op = op_with_inputs { bang_input, num_input, sym_input }
    node = RTNode :op

    assert.is.same { [sym]: sym_input }, node.side_inputs

  it 'lifts up side_inputs from children', ->
    event_value = T.bang\mk_evt!
    event_input = Input.hot event_value
    event = RTNode op: op_with_inputs { event_input }
    assert.is.same { [event_value]: event_input }, event.side_inputs

    value_value = T.num\mk_sig 4
    value_input = Input.hot value_value
    value = RTNode op: op_with_inputs { value_input }
    assert.is.same { [value_value]: value_input }, value.side_inputs

    node = RTNode children: { event, value }
    assert.is.same { [event_value]: event_input, [value_value]: value_input },
                   node.side_inputs

  describe ':tick', ->
    local a_value, a_child, a_input
    local b_value, b_child, b_input
    before_each ->
      a_value = T.num\mk_evt!
      a_input = Input.hot a_value
      a_child = node_with_sideinput a_value, a_input

      b_value = T.num\mk_evt!
      b_input = Input.hot b_value
      b_child = node_with_sideinput b_value, b_input

    it 'updates children when a side_input is dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      a = spy.on a_child, 'tick'
      b = spy.on b_child, 'tick'

      node = RTNode children: { a_child, b_child }
      node\tick!

      assert.spy(a).was_called_with match.ref a_child
      assert.spy(b).was_called_with match.ref b_child

    it 'early-outs when no side_inputs are dirty', ->
      assert.is.false a_input\dirty!
      assert.is.false b_input\dirty!

      a = spy.on a_child, 'tick'
      b = spy.on b_child, 'tick'

      node = RTNode children: { a_child, b_child }
      node\tick!

      assert.spy(a).was_not_called!
      assert.spy(b).was_not_called!

    it 'updates op when any op-inputs are dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = op_with_inputs a: Input.hot a_value
      s = spy.on op, 'tick'

      node = RTNode :op, children: { a_child, b_child }
      node\tick!

      assert.spy(s).was_called_with match.ref op

    it 'early-outs when no op-inputs are dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = op_with_inputs { Input.hot b_value }
      s = spy.on op, 'tick'

      node = RTNode :op, children: { a_child, b_child }
      node\tick!

      assert.spy(s).was_not_called!

  describe ':poll_io', ->
    it 'polls IOs referenced in side_inputs', ->
      io, input, op = dirty_op!
      node = RTNode :op

      s = spy.on io, 'poll'
      assert.is.same { [io]: input }, node.side_inputs
      node\poll_io!

      assert.spy(s).was_called_with match.ref io
