import Op, Input, match from require 'core.base'

class out extends Op
  @doc: "(out [name-str?] value) - log value to the console"

  setup: (inputs) =>
    { name, value } = match 'str? any', inputs
    super
      name: name and Input.value name
      value: Input.value value

  tick: =>
    { :name, :value } = @unwrap_all!
    L\print if name then name, value else value

{
  :out
}
