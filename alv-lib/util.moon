import Constant, Op, Input, T, sig, evt from require 'alv.base'

all_same = (list) ->
  for v in *list[2,]
    if v != list[1]
      return false

  list[1]

switch_ = Constant.meta
  meta:
    name: 'switch'
    summary: "Switch between multiple inputs."
    examples: { '(switch i v1 v2…)' }
    description: "
- when `i` is `true`, the first value is reproduced.
- when `i` is `false`, the second value is reproduced.
- when `i` is a `num`, it is [math/floor][]ed and the matching argument
  (indexed starting from 0) is reproduced."

  value: class extends Op
    val_or_evt = (sig! / evt!)!
    pattern = (sig.num / sig.bool) + val_or_evt*0
    setup: (inputs) =>
      { i, values } = pattern\match inputs

      @out = if values[1].result.metatype ~= '!'
        values[1]\type!\mk_sig!
      else
        values[1]\type!\mk_evt!

      super
        i: Input.hot i
        values: [Input.hot v for v in *values]

    tick: =>
      { :i, :values } = @inputs
      ii = switch i!
        when true then 1
        when false then 2
        else 1 + (math.floor i!) % #values

      @state = ii - 1
      @out\set values[ii] and values[ii]!

edge = Constant.meta
  meta:
    name: 'edge'
    summary: "Convert rising edges to bangs."
    examples: { '(edge bool)' }

  value: class extends Op
    setup: (inputs) =>
      @out or= T.bang\mk_evt!
      value = sig.bool\match inputs
      super value: Input.hot value

    tick: =>
      now = @inputs.value!
      if now and not @state
        @out\set true
      @state = now

{
  'switch': switch_
  :edge
}
