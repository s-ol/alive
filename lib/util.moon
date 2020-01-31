import Op from require 'base'

class pick extends Op
  setup: (@i, ...) =>
    @choices = { ... }

  update: =>
    i = 1 + (math.floor @i\get!) % #@choices
    @value = @choices[i]\get!

{
  :pick
}
