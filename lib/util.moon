import Op, Value, Input, match
  from require 'core.base'

all_same = (list) ->
  for v in *list[2,]
    if v != list[1]
      return false

  list[1]

class switch_ extends Op
  @doc: "(switch i v0 [v1 v2...]) - switch between multiple inputs

when i is true, the first value is reproduced.
when i is false, the second value is reproduced.
when i is a num, it is (floor)ed and the matching argument (starting from 0) is reproduced."

  setup: (inputs) =>
    { i, values } = match 'any *any', inputs

    i_type = i\type!
    assert i_type == 'bool' or i_type == 'num', "#{@}: i has to be bool or num"
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

class route extends Op
  @doc: "(route i v0 [v1 v2...]) - route between multiple inputs

when i is true, the first value is reproduced.
when i is false, the second value is reproduced.
when i is a num, it is (floor)ed and the matching argument (starting from 0) is reproduced."

  setup: (inputs) =>
    { i, values } = match 'any *any', inputs

    i_type = i\type!
    assert i_type == 'bool' or i_type == 'num', "#{@}: i has to be bool or num"
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

--class switch_pause extends Op
--  @doc: "(switch- i v0 [v1 v2...]) - switch and pause multiple inputs
--
--like (switch ...) except that the unused inputs are paused."
--
--  setup: (@i, ...) =>
--    @choices = { ... }
--
--    typ = @choices[1].type
--    for inp in *@choices[2,]
--      assert inp.type == typ, "not all values have the same type: #{typ} != #{inp.type}"
--
--    @out = Stream typ
--    @out
--
--  tick: =>
--    i = @i\unwrap!
--    active = switch i
--      when true
--        @choices[1]
--      when false
--        @choices[2]
--      else
--        i = 1 + (math.floor i) % #@choices
--        @choices[i]
--
--    @out\set if active
--      active\unwrap!

class edge extends Op
  @doc: "(edge bool) - convert rising edges to bangs"
  new: => super 'bang'

  setup: (inputs) =>
    { value } = match 'bool', inputs
    super value: Input.value value

  tick: =>
    now = @inputs.value!
    if now and not @last
      @out\set true
      @last = now

class default extends Op
  @doc: "(default stream default) - provide a default value for an event stream

starts out as default but forwards events from stream.
default defaults to zero."

  setup: (params) =>
    { value, init } = match 'any any', inputs
    super
      value: Input.event value
      init: Input.cold init

    @out = Value value\type!
    @out\set @inputs.init\unwrap!

  tick: =>
    { :value } = @inputs
    if value\dirty!
      @out\set value!

{
  'switch': switch_
  :route
  :edge
  :default
}
