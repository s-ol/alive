import PureOp, Constant, T, sig, evt from require 'alv.base'

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

any = sig! / evt!

class ReduceOp extends PureOp
  pattern: any\rep 2, nil
  type: T.bool

  tick: =>
    args = @unwrap_all!
    accum = tobool args[1]
    for val in *args[2,]
      accum = @.fn accum, tobool val

    @out\set accum

eq = Constant.meta
  meta:
    name: 'eq'
    summary: "Check for equality."
    examples: { '(== a b [c]…)', '(eq a b [c]…)' }
    description: "`true` if the types and values of all arguments are equal."

  value: class extends ReduceOp
    setup: (inputs) =>
      @state or= {}
      @state.same_type = all_same inputs[1]\type!, [i\type! for i in *inputs[2,]]
      super inputs

    tick: =>
      if not @state.same_type
        @out\set false
        return

      typ = @inputs[1]\type!
      args = @unwrap_all!
      equal, first = true, args[1]
      for other in *args[2,]
        if not typ\eq first, other
          equal = false
          break

      @out\set equal

not_eq = Constant.meta
  meta:
    name: 'not-eq'
    summary: "Check for inequality."
    examples: { '(!= a b [c]…)', '(not-eq a b [c]…)' }
    description: "`true` if types or values of any two arguments are different."

  value: class extends ReduceOp
    setup: (inputs) =>
      @state or= {}
      @state.same_type = all_same inputs[1]\type!, [i\type! for i in *inputs[2,]]
      super inputs

    tick: =>
      if not @state.same_type
        @out\set true
        return

      typ = @inputs[1]\type!
      args = @unwrap_all!
      diff, first = true, args[1]
      for other in *args[2,]
        if typ\eq first, other
          diff = false
          break

      @out\set diff

and_ = Constant.meta
  meta:
    name: 'and'
    summary: "Logical AND."
    examples: { '(and a b [c…])' }
  value: class extends ReduceOp
    fn: (a, b) -> a and b

or_ = Constant.meta
  meta:
    name: 'or'
    summary: "Logical OR."
    examples: { '(or a b [c…])' }
  value: class extends ReduceOp
    fn: (a, b) -> a or b

not_ = Constant.meta
  meta:
    name: 'not'
    summary: "Logical NOT."
    examples: { '(not a)' }

  value: class extends PureOp
    pattern: any\rep 1, 1
    type: T.bool
    tick: => @out\set not tobool @inputs[1]!

bool = Constant.meta
  meta:
    name: 'bool'
    summary: "Cast value to bool."
    examples: { '(bool a)' }
    description: "`false` if a is `false`, `nil` or `0`, `true` otherwise."

  value: class extends PureOp
    pattern: any\rep 1, 1
    type: T.bool
    tick: => @out\set tobool @inputs[1]!

Constant.meta
  meta:
    name: 'logic'
    summary: "Logical operations."

  value:
    :eq, '==': eq
    'not-eq': not_eq, '!=': not_eq
    and: and_
    or: or_
    not: not_
    :bool
