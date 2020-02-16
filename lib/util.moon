import Stream, Const, Op from require 'core'

class switch_ extends Op
  @doc: "(switch i v0 [v1 v2...]) - switch between multiple inputs

when i is true, the first value is reproduced.
when i is false, the second value is reproduced.
when i is a num, it is (floor)ed and the matching argument (starting from 0) is reproduced."

  setup: (@i, ...) =>
    @choices = { ... }

    typ = @choices[1].type
    for inp in *@choices[2,]
      assert inp.type == typ, "not all values have the same type: #{typ} != #{inp.type}"

    @out = Stream typ
    @out

  update: (dt) =>
    i = @i\unwrap!
    active = switch i
      when true
        @choices[1]
      when false
        @choices[2]
      else
        i = 1 + (math.floor i) % #@choices
        @choices[i]
    @out\set active and active\unwrap!

class switch_pause extends Op
  @doc: "(switch- i v0 [v1 v2...]) - switch and pause multiple inputs

like (switch ...) except that the unused inputs are paused."

  setup: (@i, ...) =>
    @choices = { ... }

    typ = @choices[1].type
    for inp in *@choices[2,]
      assert inp.type == typ, "not all values have the same type: #{typ} != #{inp.type}"

    @out = Stream typ
    @out

  update: (dt) =>
    i = @i\unwrap!
    active = switch i
      when true
        @choices[1]
      when false
        @choices[2]
      else
        i = 1 + (math.floor i) % #@choices
        @choices[i]

    @out\set if active
      active\unwrap!

class edge extends Op
  setup: (@i) =>
    @last = false
    @out = Stream @i.type
    @out

  update: (dt) =>
    now = @i\unwrap!
    @out\set not @last and now
    @last = now

class keep extends Op
  @doc: "(keep value [default]) - keep the last non-nil value

always reproduces the last non-nil value the input produced or default.
default defaults to zero."

  setup: (@i, @default=Const.num 0) =>
    @out = Stream @i.type, @default.value
    @out

  update: (dt) =>
    if next = @i\unwrap!
      @out\set next

{
  'switch': switch_
  'switch-': switch_pause
  :edge
  :keep
}
