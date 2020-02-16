import Op from require 'core'

class out extends Op
  @doc: "(out name-str value) - log value to the console"

  setup: (@name, @value) =>

  update: (dt) =>
    L\print "#{@name\unwrap 'str'}", @value\unwrap!

{
  :out
}
