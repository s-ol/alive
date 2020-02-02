import Op from require 'base'

class out extends Op
  setup: (name, @chld) =>
    @name = name\getc!

  update: =>
    L\print "@name", @chld\get!

{
  :out
}
