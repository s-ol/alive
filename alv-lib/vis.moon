import Constant, Op, T, Input, sig, evt from require 'alv.base'

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

      @out = val.result\fork!

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

{
  :bar
}
