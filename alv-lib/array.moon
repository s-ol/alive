import PureOp, Constant, T, Array, val, evt from require 'alv.base'

any = val! / evt!

array = Constant.meta
  meta:
    name: 'array'
    summary: "Construct an array."
    examples: { '(array a b c…)' }
    description: "Produces an array of values."

  value: class extends PureOp
    pattern: any!*0
    type: (args) => Array #args, args[1]\type!

    tick: =>
      args = @unwrap_all!
      @out\set args

{
  :array
}
