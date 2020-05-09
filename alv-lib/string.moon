import Op, Constant, SigStream, Input, T from require 'alv.base'

str = Constant.meta
  meta:
    name: 'str'
    summary: "Concatenate/stringify values."
    examples: { '(.. v1 [v2…])', '(str v1 [v2…])' }
  value: class extends Op
    setup: (inputs) =>
      @out or= SigStream T.str
      super [Input.hot v for v in *inputs]

    tick: =>
      @out\set table.concat [tostring v! for v in *@inputs]

{
  :str, '..': str
}
