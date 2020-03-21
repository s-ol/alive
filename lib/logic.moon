import Op, Value, Input, Error, match from require 'core.base'

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

eq = Value.meta
  meta:
    name: 'eq'
    summary: "Check for equality."
    examples: { '(== a b [c]...)', '(eq a b [c]...)' }
    description: "`true` if the types and values of all arguments are equal."

  value: class extends Op
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


not_eq = Value.meta
  meta:
    name: 'not-eq'
    summary: "Check for inequality."
    examples: { '(!= a b [c]...)', '(not-eq a b [c]...)' }
    description: "`true` if types or values of any two arguments are different."

  value: class extends Op
    new: => super 'bool'

    setup: (inputs) =>
      assert #inputs > 1, Error 'argument', "need at least two values"
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

and_ = Value.meta
  meta:
    name: 'and'
    summary: "Logical AND."
    examples: { '(and a b [c…])' }
  value: class extends ReduceOp
    fn: (a, b) -> a and b

or_ = Value.meta
  meta:
    name: 'or'
    summary: "Logical OR."
    examples: { '(or a b [c…])' }
  value: class extends ReduceOp
    fn: (a, b) -> a or b

not_ = Value.meta
  meta:
    name: 'not'
    summary: "Logical NOT."
    examples: { '(not a)' }

  value: class extends Op
    new: => super 'bool'

  setup: (inputs) =>
    { value } = match 'any', inputs
    super value: Input.value value

  tick: => @out\set not tobool @inputs.value!

bool = Value.meta
  meta:
    name: 'bool'
    summary: "Cast value to bool."
    examples: { '(bool a)' }
    description: "`false` if a is `false`, `nil` or `0`, `true` otherwise."

  value: class extends Op
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
