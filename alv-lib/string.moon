import PureOp, Constant, Input, T, val, evt from require 'alv.base'

any = val! / evt!

str = Constant.meta
  meta:
    name: 'str'
    summary: "Concatenate/stringify values."
    examples: { '(.. v1 [v2…])', '(str v1 [v2…])' }
  value: class extends PureOp
    pattern: any\rep 1, nil
    type: T.str
    tick: => @out\set table.concat [tostring i! for i in *@inputs]

{
  :str, '..': str
}
