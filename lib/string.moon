import Op, Input from require 'core.base'

class str extends Op
  @doc: "(str v1 [v2]...)
(.. v1 [v2]...) - concatenate/stringify values"
  new: => super 'str'

  setup: (inputs) => super [Input.value v for v in *inputs]
  tick: => @out\set table.concat [tostring v! for v in *@inputs]

{
  :str, '..': str
}
