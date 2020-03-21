import Op, Value, Input, Error, match from require 'core.base'

all_same = (list) ->
  for v in *list[2,]
    if v != list[1]
      return false

  list[1]

switch_ = Value.meta
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
    setup: (inputs) =>
      { i, values } = match 'any *any', inputs

      i_type = i\type!
      assert i_type == 'bool' or i_type == 'num', Error 'argument', "i has to be bool or num"
      typ = all_same [v\type! for v in *values]
      @out = Value typ if not @out or typ != @out.type

      super
        i: Input.value i
        values: [Input.value v for v in *values]

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
      @out\set active and active!

route = Value.meta
  meta:
    name: 'route'
    summary: "Route between multiple inputs."
    examples: { '(route i v0 [e1 e2…])' }
    description: "
- when `i` is `true`, the first event stream is reproduced.
- when `i` is `false`, the second event stream is reproduced.
- when `i` is a `num`, it is [math/floor][]ed and the matching argument
  (indexed starting from 0) is reproduced."

  value: class extends Op
    setup: (inputs) =>
      { i, values } = match 'any *any', inputs

      i_type = i\type!
      assert i_type == 'bool' or i_type == 'num', Error 'argument', "i has to be bool or num"
      typ = all_same [v\type! for v in *values]
      @out = Value typ if not @out or typ != @out.type

      super
        i: Input.value i
        values: [Input.value v for v in *values]

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
      if active and active\dirty!
        @out\set active!

route = Value.meta
  meta:
    name: 'edge'
    summary: "Convert rising edges to bangs."
    examples: { '(edge bool)' }

  value: class extends Op
    new: => super 'bang'

    setup: (inputs) =>
      { value } = match 'bool', inputs
      super value: Input.value value

    tick: =>
      now = @inputs.value!
      if now and not @state.last
        @out\set true
        @state.last = now

{
  'switch': switch_
  :route
  :edge
}
