import Op, Input, match from require 'core.base'

all_same = (first, list) ->
  for v in *list
    if v != first
      return false

  first

tobool = (val) ->
  switch val
    when false, nil, 0
      false
    else
      true

class ReduceOp extends Op
  new: => super 'bool'

  setup: (inputs) =>
    { first, rest } = match "any *any", inputs
    super
      first: Input.value first
      rest: [Input.value v for v in *rest]

  tick: =>
    { :first, :rest } = @unwrap_all!
    accum = tobool first
    for val in *rest
      accum = @.fn accum, tobool val

    @out\set accum

class eq extends Op
  @doc: "(eq a b [c]...)
(== a b [c]...) - check for equality

If the value types dont match, the result is an eval-time constant 'false'."

  new: => super 'bool', false

  setup: (inputs) =>
    { first, rest } = match "any *any", inputs
    same = all_same first\type!, [i\type! for i in *rest]

    super if same
      {
        first: Input.value first
        rest: [Input.value v for v in *rest]
      }
    else
      {}

  tick: =>
    if not @inputs.first
      @out\set false
      return

    { :first, :rest } = @unwrap_all!

    equal = true
    for other in *rest
      if first != other
        equal = false
        break

    @out\set equal

class not_eq extends Op
  @doc: "(not-eq a b [c]...)
(!= a b [c]...) - check for inequality"
  new: => super 'bool'

  setup: (inputs) =>
    assert #inputs > 1, "neq need at least two values"
    super [Input.value v for v in *inputs]

  tick: =>
    if not @inputs[1]
      @out\set true
      return

    diff = true
    for a=1, #@inputs-1
      for b=a+1, #@inputs
        if @inputs[a].stream == @inputs[b].stream
          diff = false
          break

      break unless diff

    @out\set diff

class and_ extends ReduceOp
  @doc: "(and a b [c]...) - AND values"
  fn: (a, b) -> a and b

class or_ extends ReduceOp
  @doc: "(or a b [c]...) - OR values"
  fn: (a, b) -> a or b

class not_ extends Op
  @doc: "(not a) - boolean opposite"
  new: => super 'bool'

  setup: (inputs) =>
    { value } = match 'any', inputs
    super value: Input.value value

  tick: => @out\set not tobool @inputs.value!

class bool extends Op
  @doc: "(bool a) - convert to bool"
  new: => super 'bool'

  setup: (inputs) =>
    { value } = match 'any', inputs
    super value: Input.value value

  tick: => @out\set tobool @inputs\value!

{
  :eq, '==': eq
  'not-eq': not_eq, '!=': not_eq
  and: and_
  or: or_
  not: not_
  :bool
}
