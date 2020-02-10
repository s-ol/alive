import Op from require 'core'

class switch_ extends Op
  @doc: "(switch i v0 [v1 v2...]) - switch between multiple inputs

when i is true, the first value is reproduced.
when i is false, the second value is reproduced.
when i is a num, it is (floor)ed and the matching argument (starting from 0) is reproduced."

  setup: (@i, ...) =>
    @choices = { ... }

  update: (dt) =>
    @i\update dt
    i = @i\get!

    for choice in *@choices
      choice\update dt

    active = switch @i\get!
      when true
        @choices[1]
      when false
        @choices[2]
      else
        i = 1 + (math.floor i) % #@choices
        @choices[i]
    @value = active and active\get!

class switch_pause extends Op
  @doc: "(switch- i v0 [v1 v2...]) - switch and pause multiple inputs

like (switch ...) except that the unused inputs are paused."

  setup: (@i, ...) =>
    @choices = { ... }

  update: (dt) =>
    @i\update dt
    i = @i\get!
    active = switch @i\get!
      when true
        @choices[1]
      when false
        @choices[2]
      else
        i = 1 + (math.floor i) % #@choices
        @choices[i]

    @value = if active
      active\update dt
      active\get!

class keep extends Op
  @doc: "(keep value) - keep the last non-nil value

always reproduces the last non-nil value the input produced"

  setup: (@i) =>

  update: (dt) =>
    @i\update dt

    next = @i\get!
    @value = next or @value

{
  'switch': switch_
  'switch-': switch_pause
  :keep
}
