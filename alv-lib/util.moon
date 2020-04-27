import Op, ValueStream, EventStream, Input, val, evt from require 'alv.base'

all_same = (list) ->
  for v in *list[2,]
    if v != list[1]
      return false

  list[1]

switch_ = ValueStream.meta
  meta:
    name: 'switch'
    summary: "Switch between multiple inputs."
    examples: { '(switch i v0 [v1 v2…])' }
    description: "
- when `i` is `true`, the first value is reproduced.
- when `i` is `false`, the second value is reproduced.
- when `i` is a `num`, it is [math/floor][]ed and the matching argument
  (indexed starting from 0) is reproduced."

  value: class extends Op
    val_or_evt = (val! / evt!)!
    pattern = (val.num / val.bool) + val_or_evt*0
    setup: (inputs) =>
      { i, values } = pattern\match inputs

      @state = values[1].value.__class == ValueStream

      @out = if @state
        ValueStream values[1]\type!
      else
        EventStream values[1]\type!

      super
        i: Input.hot i
        values: [Input.hot v for v in *values]

    tick: =>
      { :i, :values } = @inputs
      active = switch i!
        when true
          values[1]
        when false
          values[2]
        else
          i = 1 + (math.floor i!) % #values
          values[i]
      if @state
        @out\set active and active!
      else
        if active and active\dirty!
          for event in *active!
            @out\add event

edge = ValueStream.meta
  meta:
    name: 'edge'
    summary: "Convert rising edges to bangs."
    examples: { '(edge bool)' }

  value: class extends Op
    setup: (inputs) =>
      @out or= EventStream 'bang'
      value = val.bool\match inputs
      super value: Input.hot value

    tick: =>
      now = @inputs.value!
      if now and not @state
        @out\add true
      @state = now

change = ValueStream.meta
  meta:
    name: 'change'
    summary: "Convert value changes to events."
    examples: { '(change val)' }

  value: class extends Op
    setup: (inputs) =>
      value = val!\match inputs
      @out or= EventStream value\type!
      super value: Input.hot value

    tick: =>
      now = @inputs.value!
      if now != @state
        @out\add @inputs.value!
        @state = now

hold = ValueStream.meta
  meta:
    name: 'hold'
    summary: "Convert events to value changes."
    examples: { '(hold evt)' }

  value: class extends Op
    setup: (inputs) =>
      event = evt!\match inputs
      @out or= ValueStream event\type!
      super event: Input.hot event

    tick: =>
      for val in *@inputs.event!
        @out\set val

{
  'switch': switch_
  :edge
  :change
  :hold
}
