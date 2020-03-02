import Op, ValueInput from require 'core'

class str extends Op
  @doc: "(str v1 [v2]...)
(.. v1 [v2]...) - concatenate/stringify values"
  new: => super 'str'

  setup: (inputs) => super [ValueInput v for v in *inputs]
  tick: => @out\set table.concat [tostring v! for v in *@inputs]

{
  :str, '..': str
}
