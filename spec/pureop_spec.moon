import do_setup, do_teardown, invoke_op from require 'spec.test_setup'
import PureOp, Input, T, sig, any from require 'alv.base'
import RTNode from require 'alv'

setup do_setup
teardown do_teardown

class TestPureOp extends PureOp
  pattern: (any.num / sig.str)*3
  type: T.num
  tick: => @out\set 1

literal = (result) ->
  eval: ->
    si = T.num\mk_sig!
    RTNode :result, side_inputs: { [si]: Input.hot si }

describe 'PureOp', ->
  it 'matches the pattern', ->
    assert.has.error -> invoke_op TestPureOp, {}
    assert.has.error -> invoke_op TestPureOp, { literal T.bool\mk_evt! }
    invoke_op TestPureOp, { literal T.num\mk_const 1 }
    invoke_op TestPureOp, { literal T.str\mk_const 'hello' }
    invoke_op TestPureOp, { literal T.num\mk_evt! }

  describe 'with constant inputs', ->
    local rtn
    it 'ticks once', ->
      tiq = spy.on TestPureOp.__base, 'tick'
      rtn = invoke_op TestPureOp, { T.num\mk_const(1), T.str\mk_const('hello') }
      assert.spy(tiq).was_called_with match.is_ref(rtn.op), true
      assert.is.equal 1, rtn.result!

    it 'is constant', ->
      assert.is.equal '=', rtn\metatype!

  describe 'with signal inputs', ->
    a = T.num\mk_sig 1
    b = T.num\mk_sig 2
    c = T.num\mk_sig 3
    tiq = spy.on TestPureOp.__base, 'tick'
    rtn = invoke_op TestPureOp, { (literal a), (literal b), (literal c) }
    op = rtn.op

    it 'sets up hot inputs', ->
      assert.is.equal 3, #op.inputs
      assert.is.equal a, op.inputs[1].result
      assert.is.equal b, op.inputs[2].result
      assert.is.equal c, op.inputs[3].result
      assert.is.equal 'hot', op.inputs[1].mode
      assert.is.equal 'hot', op.inputs[2].mode
      assert.is.equal 'hot', op.inputs[3].mode
      assert.spy(tiq).was_called!

    it 'has signal output', ->
      assert.is.equal '~', op.out.metatype

  describe 'with event inputs', ->
    a = T.num\mk_sig 1
    b = T.num\mk_evt 2
    c = T.num\mk_sig 3
    tiq = spy.on TestPureOp.__base, 'tick'
    rtn = invoke_op TestPureOp, { (literal a), (literal b), (literal c) }
    op = rtn.op

    it 'sets up hot input only for evt', ->
      assert.is.equal 3, #op.inputs
      assert.is.equal a, op.inputs[1].result
      assert.is.equal b, op.inputs[2].result
      assert.is.equal c, op.inputs[3].result
      assert.is.equal 'cold', op.inputs[1].mode
      assert.is.equal 'hot', op.inputs[2].mode
      assert.is.equal 'cold', op.inputs[3].mode
      assert.spy(tiq).was_not_called!

    it 'has event output', ->
      assert.is.equal '!', op.out.metatype

  it 'only allows one event input', ->
    a, b = T.num\mk_evt!, T.num\mk_evt!
    assert.has.error -> invoke_op TestPureOp, { (literal a), (literal b) }

  it 'supports nested input patterns', ->
    class NestedInputOp extends PureOp
      pattern: (any.num + sig.str)\named('a', 'b')\rep 2, 2
      type: T.num
      tick: => @out\set 1

    num = T.num\mk_sig 1
    str = T.str\mk_sig 'hello'
    oth = T.num\mk_evt 2
    args = { (literal num), (literal str), (literal oth), (literal str) }
    rtn = invoke_op NestedInputOp, args
    op = rtn.op

    assert.is.equal 2, #op.inputs
    assert.is.equal num, op.inputs[1].a.result
    assert.is.equal str, op.inputs[1].b.result
    assert.is.equal oth, op.inputs[2].a.result
    assert.is.equal str, op.inputs[2].b.result
    assert.is.equal 'cold', op.inputs[1].a.mode
    assert.is.equal 'cold', op.inputs[1].b.mode
    assert.is.equal 'hot', op.inputs[2].a.mode
    assert.is.equal 'cold', op.inputs[2].b.mode

  it 'supports dynamically generating the output type', ->
    class DynamicOp extends PureOp
      pattern: sig.num + any!
      type: (inputs) => inputs[2]\type!
      tick: => @out\set @inputs[2]!
    typ = spy.on DynamicOp, 'type'

    a = T.num\mk_sig 1
    num = T.num\mk_sig 1
    str = T.str\mk_sig 1
    sym = T.sym\mk_evt 1

    rtn = invoke_op DynamicOp, { (literal a), (literal num) }
    assert.is.equal '~', rtn.result.metatype
    assert.is.equal num, rtn.result

    rtn = invoke_op DynamicOp, { (literal a), (literal str) }
    assert.is.equal '~', rtn.result.metatype
    assert.is.equal str, rtn.result

    rtn = invoke_op DynamicOp, { (literal a), (literal sym) }
    assert.is.equal '!', rtn.result.metatype
    assert.is.equal T.sym, rtn.result.type
