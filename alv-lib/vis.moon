import Constant, Op, T, Array, Input, sig, evt from require 'alv.base'

bar = Constant.meta
  meta:
    name: 'bar'
    summary: "visualize number as a bar."
    examples: { '(vis/bar val [[min] max])' }
    description: "
Visualizes `val` as a bar with range `min, max`.
`val` can be a `num~` or `num!`, `min` and `max` are optional `num~`.
`min` defaults to `0` and `max` defaults to `1`."

  value: class extends Op
    pattern = (sig.num / evt.num) + -sig.num + -sig.num
    setup: (inputs, scope) =>
      { val, min, max } = pattern\match inputs
      if not max
        min, max = nil, min

      @out = if val.result.metatype ~= '!'
        val\type!\mk_sig!
      else
        val\type!\mk_evt!

      super
        val: Input.hot val
        min: Input.cold min or Constant.num 0
        max: Input.cold max or Constant.num 1

    tick: =>
      { :val, :min, :max } = @unwrap_all!
      delta = max - min
      @state = (val / delta) - min
      @out\set val

    vis: =>
      {
        type: 'bar'
        bar: @state
      }

rgb = Constant.meta
  meta:
    name: 'rgb'
    summary: "visualize an array as an RGB color."
    examples: { '(vis/rgb val [range])' }
    description: "
Visualizes `val` as an RGB(A) color with each component in range `0 - range`.
`val` needs to be a `[3]num~`, `[3]num!`, `[4]num~`, or `[4]num!`.
`range` is a `num~` and defaults to `1`."

  value: class extends Op
    a3 = (Array 3, T.num)
    a4 = (Array 4, T.num)
    color = (sig a3) / (sig a4) / (evt a3) / (evt a4)
    pattern = color + -sig.num
    setup: (inputs, scope) =>
      { val, max } = pattern\match inputs

      @out = if val.result.metatype ~= '!'
        val\type!\mk_sig!
      else
        val\type!\mk_evt!

      super
        val: Input.hot val
        max: Input.cold max or Constant.num 1

    tick: =>
      { :val, :max } = @unwrap_all!
      @out\set val
      @state = [i/max for i in *val]

    vis: =>
      {
        type: 'rgb'
        rgb: @state
      }

{
  :bar
  :rgb
}
