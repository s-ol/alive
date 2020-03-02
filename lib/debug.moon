import Op, ValueInput, EventInput, match from require 'core'

class out extends Op
  @doc: "(out [name-str?] value) - log value to the console"

  setup: (inputs) =>
    { name, value } = match 'str? any', inputs
    super
      name: name and ValueInput name
      value: ValueInput value

  tick: =>
    { :name, :value } = @unwrap_all!
    L\print if name then name, value else value

{
  :out
}
