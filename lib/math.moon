import Op from require 'base'
unpack or= table.unpack

class BinOp extends Op
  setup: (...) =>
    @children = { ... }
    assert #@children >= 2, "#{@} needs at least two parameters"

class add extends BinOp
  update: =>
    @value = 0
    for child in *@children
      @value += child\get!

class sub extends BinOp
  update: =>
    @value = @children[1]\get!
    for child in *@children[2,]
      @value -= child\get!

class mul extends BinOp
  update: =>
    @value = 1
    for child in *@children
      @value *= child\get!

class div extends BinOp
  update: =>
    @value = @children[1]\get!
    for child in *@children[2,]
      @value /= child\get!

func_op = (name, arity, func) ->
  k = class extends Op
    setup: (...) =>
      @params = { ... }
      if arity != '*'
        assert #@params == arity, "#{@} needs exactly #{arity} parameters"

    update: =>
      @value = func unpack [param\get! for param in *@params]

  k.__name = name
  k

module = {
  :add, '+': add
  :sub, '-': sub
  :mul, '*': mul
  :div, '/': div

  mix: func_op 'mix', 3, (a, b, i) -> i*b + (1-i)*a
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
