import Constant, Op, Builtin, Input, Error, T, any, const from require "alv.base"
import Tag, Cell from require "alv"

assert_ = Constant.meta
  meta:
    name: 'assert'
    summary: "Throw an error if a condition is false."
    examples: { "(assert check [msg])" }
    description: "
Check is any bool result. When it is `false`, this op throws an error.
`msg` is a str= value that is used as the error message.
By default, the message contains the failing check expression."

  value: class extends Builtin
    assertOp = class extends Op
      pattern = any.bool + const.str
      setup: (inputs) =>
        { check, msg } = pattern\match inputs

        super
          check: Input.hot check
          msg: msg and Input.cold msg

      tick: =>
        { :check, :msg } = @unwrap_all!

        if not check
          error Error 'assertion', msg or "assertion failed"

    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1 or #tail == 2, "'assert' takes one or two arguments"

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, {
        Constant.literal T.opdef, assertOp, 'assert'
        tail[1]
        tail[2] or Constant.str "assertion failed: #{tail[1]\stringify 2}"
      }
      super inner\eval scope

expect_eq = Constant.meta
  meta:
    name: 'expect='
    summary: "Throw an error if arguments aren't equal."
    examples: { "(expect= expected actual [actual…])" }
    description: "
Check if `expected` and `actual` are equal.
If not, throws an error."

  value: class extends Builtin
    expectOp = class extends Op
      pattern = any! + (any! + const.str)\named('val', 'src')*0
      setup: (inputs) =>
        { expected, values } = pattern\match inputs

        super
          expected: Input.hot expected
          values: [Input.hot got.val for got in *values]
          sources: [Input.cold got.src for got in *values]

        type = expected\type!
        for i, val in ipairs @inputs.values
          same = type == val\type!
          assert same, Error 'assertion', "Expected #{@inputs.sources[i]!} to equal #{expected.result} (got #{val.result})"

      tick: =>
        type = @inputs.expected\type!
        expected = @inputs.expected!

        for i, val in ipairs @inputs.values
          assert (type\eq expected, val!), Error 'assertion', "Expected #{@inputs.sources[i]!} to equal #{@inputs.expected.result} (got #{val.result})"

    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 1, "'expect=' takes at least two arguments"

      children = {
        Constant.literal T.opdef, expectOp, 'assert'
        tail[1]
      }
      for arg in *tail[2,]
        table.insert children, arg
        table.insert children, Constant.str arg\stringify 2

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, children
      super inner\eval scope

Constant.meta
  meta:
    name: 'testing'
    summary: "Operators for testing."

  value:
    'assert': assert_
    'expect=': expect_eq
