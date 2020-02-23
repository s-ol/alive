import Value, Op from require 'core'

class switch_ extends Op
  @doc: "(switch i v0 [v1 v2...]) - switch between multiple inputs

when i is true, the first value is reproduced.
when i is false, the second value is reproduced.
when i is a num, it is (floor)ed and the matching argument (starting from 0) is reproduced."

  setup: (params) =>
    super params

    { i, first } = @inputs
    assert i.type == 'bool' or i.type == 'num', "#{@}: i has to be bool or num"

    for inp in *@inputs[3,]
      assert inp.type == first.type, "not all values have the same type: #{first.type} != #{inp.type}"
    @out = Value first.type, first!

  tick: =>
    i = @inputs[1]\unwrap!
    active = switch i
      when true
        @inputs[2]
      when false
        @inputs[3]
      else
        i = 2 + (math.floor i) % (#@inputs - 1)
        @inputs[i]
    @out\set active and active\unwrap!

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

  new: =>
    super 'bang'

  setup: (params) =>
    super params
    @assert_types 'bool'

  tick: =>
    now = @params[1]\unwrap!
    if now and not @last
      @out\set true
      @last = now

class keep extends Op
  @doc: "(keep value [init]) - keep the last non-nil value

always reproduces the last non-nil value the input produced or default.
default defaults to zero."

  setup: (params) =>
    super params
    { i, init } = @inputs
    @out = Value i.type, default and init\unwrap!

  tick: =>
    if next = @params[1]\unwrap!
      @out\set next

{
  'switch': switch_
--  'switch-': switch_pause
  :edge
  :keep
}
