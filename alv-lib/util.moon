import Constant, Op, Input, T, sig, evt from require 'alv.base'

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
  :edge
}
