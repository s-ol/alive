import Op, Value, Input from require 'core.base'

str = Value.meta
  meta:
    name: 'str'
    summary: "Concatenate/stringify values."
    examples: { '(.. v1 [v2…])', '(str v1 [v2…])' }
  value: class extends Op
    new: => super 'str'

    setup: (inputs) => super [Input.value v for v in *inputs]
    tick: => @out\set table.concat [tostring v! for v in *@inputs]

{
  :str, '..': str
}
