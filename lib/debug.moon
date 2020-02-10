import Op from require 'core'

class out extends Op
  @doc: "(out name-str value) - log value to the console"

  setup: (name, @chld) =>
    @name = name\getc!

  update: (dt) =>
    @chld\update dt
    L\print "@name", @chld\get!

{
  :out
}
