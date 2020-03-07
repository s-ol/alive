import Op, Value, Input, match from require 'core.base'
unpack or= table.unpack

class ReduceOp extends Op
  new: => super 'num'

  setup: (inputs) =>
    { first, rest } = match 'num *num', inputs
    super
      first: Input.value first
      rest: [Input.value v for v in *rest]

  tick: =>
    { :first, :rest } = @unwrap_all!
    accum = first
    for val in *rest
      accum = @.fn accum, val
    @out\set accum

class add extends ReduceOp
  @doc: "(+ a b [c]...)
(add a b [c]...) - add values"

  fn: (a, b) -> a + b

class sub extends ReduceOp
  @doc: "(- a b [c]...)
(sub a b [c]...) - subtract values

subtracts all other arguments from a"

  fn: (a, b) -> a - b

class mul extends ReduceOp
  @doc: "(* a b [c]...)
(mul a b [c]...) - multiply values"

  fn: (a, b) -> a * b

class div extends ReduceOp
  @doc: "(/ a b [c]...)
(div a b [c]...) - divide values

divides a by all other arguments"

  fn: (a, b) -> a / b

evenodd_op = (name, remainder) ->
  class k extends Op
    new: => super 'bool'

    setup: (inputs) =>
      { val, div } = match 'num num?', inputs
      super
        val: Input.value val
        div: Input.value div or Value.num 2

    tick: =>
      { :val, :div } = @unwrap_all!
      @out\set (val % div) == remainder

  k.__name = name
  k.doc = "(#{name} a [div]) - check for #{name} divison

div defaults to 2"
  k

func_op = (name, arity, func) ->
  k = class extends Op
    new: => super 'num'

    setup: (inputs) =>
      { params } = match '*num', inputs
      assert #params == arity, "#{@} needs exactly #{arity} parameters" if arity != '*'
      super [Input.value p for p in *params]

    tick: => @out\set func unpack @unwrap_all!

  k.__name = name
  k

mod = func_op 'mod', 2, (a, b) -> a % b

module = {
  :add, '+': add
  :sub, '-': sub
  :mul, '*': mul
  :div, '/': div
  :mod, '%': mod

  mix: func_op 'mix', 3, (a, b, i) -> i*b + (1-i)*a
  even: evenodd_op 'even', 0
  odd: evenodd_op 'odd', 1

  pi: math.pi
  tau: math.pi*2
  huge: math.huge
}

for name, arity in pairs {
  exp: 1, log: 2, log10: 1, sqrt: 1

  cos: 1, sin: 1, tan: 1
  asin: 1, acos: 1, atan: 1, atan2: 2
  sinh: 1, cosh: 1, tanh: 1

  min: '*', max: '*'

  floor: 1, ceil: 1, abs: 1
}
  module[name] = func_op name, arity, math[name]

module
