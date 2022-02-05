import do_setup from require 'spec.test_setup'
import RTNode, Scope, SimpleRegistry from require 'alv'
import T, Input, Op, Constant from require 'alv.base'

class IOOp extends Op
  new: (...) =>
    super ...
    @is_dirty = true

  poll: => @is_dirty

make_op = (Class, inputs={}) ->
  with Class!
    \setup inputs

setup do_setup

describe 'RTNode', ->
  describe 'constructor', ->
    it 'takes result, children', ->
      result = Constant.num 3

      a = RTNode!
      b = RTNode!
      children = { a, b }

      node = RTNode :result, :children

      assert.is.equal result, node.result
      assert.is.same children, node.children

    it 'takes op and detects io_ops', ->
      op = make_op Op
      rtn = RTNode :op
      assert.is.equal op, rtn.op
      assert.is.same {}, rtn.io_ops

      op = make_op IOOp
      rtn = RTNode :op
      assert.is.equal op, rtn.op
      assert.is.same { op }, rtn.io_ops

    describe 'detects Op inputs', ->
      it '(hot -> side_input)', ->
        sig = T.num\mk_sig!
        inp = Input.hot sig
        rtn = RTNode op: make_op Op, { inp }
        assert.is.same { [sig]: inp }, rtn.side_inputs

      it '(cold -> discard)', ->
        rtn = RTNode op: make_op Op, { Input.cold T.num\mk_sig! }
        assert.is.same {}, rtn.side_inputs

      it "(childrens' results -> discard)", ->
        child = RTNode op: make_op(Op), result: T.num\mk_sig 123
        parent = RTNode children: { child }, op: make_op Op, { Input.hot child.result }
        assert.is.same {}, parent.side_inputs

    describe 'lifts up', ->
      it 'side_inputs from children', ->
        expected_inputs = {}
        children = {}

        for i=1,3
          result = T.num\mk_sig!
          input = Input.hot result
          table.insert children, RTNode op: make_op Op, { input }
          expected_inputs[result] = input

        mid_rtn = RTNode children: children
        out_rtn = RTNode children: { mid_rtn }

        assert.is.same expected_inputs, mid_rtn.side_inputs
        assert.is.same expected_inputs, out_rtn.side_inputs

      it 'io_ops from children', ->
        a_op = make_op IOOp
        a_rtn = RTNode op: a_op

        b_op = make_op IOOp
        b_rtn = RTNode op: b_op

        c_op = make_op Op
        c_rtn = RTNode op: c_op

        mid_rtn = RTNode children: { a_rtn, b_rtn, c_rtn }
        out_op = make_op IOOp
        out_rtn = RTNode children: { mid_rtn }, op: out_op

        assert.is.same { a_op, b_op }, mid_rtn.io_ops
        assert.is.same { a_op, b_op, out_op }, out_rtn.io_ops

  it ':type gets type and assets value', ->
    node = RTNode result: Constant.num 2
    assert.is.equal T.num, node\type!

    node = RTNode!
    assert.has.error -> node\type!

  it ':is_const', ->
    result = Constant.num 2
    pure = RTNode :result
    impure = RTNode op: make_op Op, { Input.hot T.num\mk_sig! }

    assert.is.true pure\is_const!
    assert.is.false impure\is_const!

    assert.is.equal result, pure\const!
    assert.has.error -> impure\const!
    assert.has.error (-> impure\const 'test'), 'test'

  it ':make_ref', ->
    result = T.num\mk_sig 2
    input = Input.hot result
    op = make_op IOOp, { input }
    thick = RTNode :result, :op, children: { RTNode!, RTNode! }
    ref = thick\make_ref!

    assert ref
    assert.is.equal thick.result, ref.result
    assert.is.same thick.side_inputs, ref.side_inputs
    assert.is.same {}, ref.children
    assert.is.same {}, ref.io_ops
    assert.is.nil ref.op

  describe ':poll_io', ->
    it 'polls all io_ops in tree', ->
      child = RTNode op: make_op IOOp
      node = RTNode children: { child }, op: make_op IOOp

      sc = spy.on child.op, 'poll'
      sn = spy.on node.op, 'poll'
      node\poll_io!

      assert.spy(sc).was_called_with match.ref child.op
      assert.spy(sn).was_called_with match.ref node.op

    it 'returns whether any ops were dirty', ->
      child = RTNode op: make_op IOOp
      node = RTNode children: { child }, op: make_op IOOp

      assert.is.true node\poll_io!

      child.op.is_dirty = false
      assert.is.true node\poll_io!

      node.op.is_dirty = false
      assert.is.false node\poll_io!

      child.op.is_dirty = true
      assert.is.true node\poll_io!

  describe ':tick', ->
    local a_value, a_child, a_input
    local b_value, b_child, b_input
    before_each ->
      a_value = T.num\mk_evt!
      a_input = Input.hot a_value
      a_child = RTNode op: make_op Op, { a_input }

      b_value = T.num\mk_evt!
      b_input = Input.hot b_value
      b_child = RTNode op: make_op Op, { b_input }

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

      op = make_op Op, { a: Input.hot a_value }
      s = spy.on op, 'tick'

      node = RTNode :op, children: { a_child, b_child }
      node\tick!

      assert.spy(s).was_called_with match.ref op

    it 'early-outs when no op-inputs are dirty', ->
      a_value\set 1
      assert.is.true a_input\dirty!
      assert.is.false b_input\dirty!

      op = make_op Op, { Input.hot b_value }
      s = spy.on op, 'tick'

      node = RTNode :op, children: { a_child, b_child }
      node\tick!

      assert.spy(s).was_not_called!
