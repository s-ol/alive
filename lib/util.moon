import Op from require 'core'

class pick extends Op
  setup: (@i, ...) =>
    @choices = { ... }

  update: (dt) =>
    @i\update dt
    for choice in *@choices
      choice\update dt

    i = 1 + (math.floor @i\get!) % #@choices
    @value = @choices[i]\get!

{
  :pick
}
