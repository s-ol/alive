import Op from require 'core'

class out extends Op
  @doc: "(out name-str value) - log value to the console"

  setup: (params) =>
    super params
    assert @inputs[2], "need a value"
    @assert_types 'str', @inputs[2].type

  tick: =>
    L\print @unwrap_inputs!

{
  :out
}
