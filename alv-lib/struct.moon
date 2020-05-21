import PureOp, Constant, T, Struct, const, val, evt from require 'alv.base'

key = const.str / const.sym
val = val! / evt!
pair = (key + val)\named 'key', 'val'

struct = Constant.meta
  meta:
    name: 'struct'
    summary: "Construct an struct."
    examples: { '(struct key1 val1 [key2 val2…])' }
    description: "Produces an struct of values."

  value: class extends PureOp
    pattern: pair*0
    type: (pairs) =>
      Struct {key.result!, val\type! for {:key, :val} in *pairs}

    tick: =>
      pairs = @unwrap_all!
      @out\set {key, val for {:key, :val} in *pairs}

{
  :struct
}
