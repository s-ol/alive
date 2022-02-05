import PureOp, Constant, Input, T, Array, any from require 'alv.base'

str = Constant.meta
  meta:
    name: 'str'
    summary: "Concatenate/stringify values."
    examples: { '(.. v1 [v2…])', '(str v1 [v2…])' }
  value: class extends PureOp
    pattern: any!\rep 1, nil
    type: T.str
    tick: =>
      strings = [i\type!\pp i!, true for i in *@inputs]
      @out\set table.concat strings

join = Constant.meta
  meta:
    name: 'join'
    summary: "Concatenate/stringify values (with separator)"
    examples: { '(join separator v1 [v2…])' }
  value: class extends PureOp
    pattern: any.str + any!\rep 1, nil
    type: T.str
    tick: =>
      strings = [i\type!\pp i!, true for i in *@inputs[2]]
      @out\set table.concat strings, @inputs[1]!

str_arr = any ((typ) -> typ.__class == Array and typ.type == T.str), "str[]"
concat = Constant.meta
  meta:
    name: 'concat'
    summary: "Concatenate string arrays."
    examples: { '(concat [separator] parts)' }
  value: class extends PureOp
    pattern: -any.str + str_arr
    type: T.str

    tick: =>
      { separator, parts } = @unwrap_all!
      @out\set table.concat parts, separator

Constant.meta
  meta:
    name: 'string'
    summary: "Utilities for dealing with strings."

  value:
    :str, '..': str
    :join
    :concat
