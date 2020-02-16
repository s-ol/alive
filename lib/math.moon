import Stream, Op, Const from require 'core'
unpack or= table.unpack

class BinOp extends Op
  new: (...) =>
    super ...
    @out = Stream 'num', 0

  setup: (...) =>
    @children = { ... }
    assert #@children >= 2, "#{@} needs at least two parameters"
    @out

class add extends BinOp
  @doc: "(+ a b [c]...)
(add a b [c]...) - add values"

  update: (dt) =>
    value = 0
    for child in *@children
      value += child\unwrap 'num'
    @out\set value

class sub extends BinOp
  @doc: "(- a b [c]...)
(sub a b [c]...) - subtract values

subtracts all other arguments from a"

  update: (dt) =>
    value = @children[1]\unwrap 'num'
    for child in *@children[2,]
      value -= child\unwrap 'num'
    @out\set value

class mul extends BinOp
  @doc: "(* a b [c]...)
(mul a b [c]...) - multiply values"

  update: (dt) =>
    value = 1
    for child in *@children
      value *= child\unwrap 'num'
    @out\set value

class div extends BinOp
  @doc: "(/ a b [c]...)
(div a b [c]...) - divide values

divides a by all other arguments"

  update: (dt) =>
    value = @children[1]\unwrap 'num'
    for child in *@children[2,]
      value /= child\unwrap 'num'
    @out\set value

evenodd_op = (name, remainder) ->
  class k extends Op
    setup: (@a, @div=Const.num 2) =>
      @out = Stream 'bool'
      @out

    update: (dt) =>
      a, divi = (@a\unwrap 'num'), @div\unwrap 'num'
      @out\set (a % divi) == remainder

  k.__name = name
  k.doc = "(#{name} a [div]) - check for #{name} divison

div defaults to 2"
  k

func_op = (name, arity, func) ->
  k = class extends Op
    setup: (...) =>
      @params = { ... }
      if arity != '*'
        assert #@params == arity, "#{@} needs exactly #{arity} parameters"

      @out = Stream 'num'
      @out

    update: (dt) =>
      @out\set func unpack [p\unwrap 'num' for p in *@params]

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

  pi: math.pi, huge: math.huge
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
