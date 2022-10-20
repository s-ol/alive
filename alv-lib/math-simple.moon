import PureOp, Input, Constant, T, any from require 'alv.base'
unpack or= table.unpack

num = any.num

class ReduceOp extends PureOp
  pattern: num\rep 2, nil
  type: T.num

  tick: =>
    args = @unwrap_all!
    accum = args[1]
    for val in *args[2,]
      accum = @.fn accum, val
    @out\set accum

func_op = (func, pattern) ->
  class extends PureOp
    pattern: pattern
    type: T.num

    tick: => @out\set func unpack @unwrap_all!

func_def = (name, args, func, summary, pattern) ->
   Constant.meta
     meta:
       :name
       :summary
       examples: { "(#{name} #{args})" }
     value: func_op func, pattern or num\rep 1, 1

evenodd_op = (remainder) ->
  class extends PureOp
    pattern: num + -num
    type: T.bool

    tick: =>
      { val, div } = @unwrap_all!
      @out\set (val % div) == remainder

add = Constant.meta
  meta:
    name: 'add'
    summary: "Add values."
    examples: { '(+ a b [c…])', '(add a b [c…])' }
    description: "Sum all arguments."
  value: class extends ReduceOp
    fn: (a, b) -> a + b

sub = Constant.meta
  meta:
    name: 'sub'
    summary: "Subtract values."
    examples: { '(- a b [c…])', '(- b)', '(sub a b [c…])' }
    description: "Subtract all other arguments from `a`.

If only `b` is given, `a` is assumed to be `0`."
  value: class extends ReduceOp
    setup: (...) =>
      super ...
      if #@inputs == 1
        table.insert @inputs, 1, Input.cold Constant.num 0

    pattern: num*0
    fn: (a, b) -> a - b

mul = Constant.meta
  meta:
    name: 'mul'
    summary: "Multiply values."
    examples: { '(* a b [c…])', '(mul a b [c…])' }
  value: class extends ReduceOp
    fn: (a, b) -> a * b

div = Constant.meta
  meta:
    name: 'div'
    summary: "Divide values."
    examples: { '(/ a b [c…])', '(div a b [c…])' }
    description: "Divide `a` by all other arguments."
  value: class extends ReduceOp
    fn: (a, b) -> a / b

pow = Constant.meta
  meta:
    name: 'pow'
    summary: "Raise to a power."
    examples: { '(^ base exp)', '(pow base exp' }
    description: "Raise `base` to the power `exp`."
  value: class extends ReduceOp
    fn: (a, b) -> a ^ b

mod = Constant.meta
  meta:
    name: 'mod'
    summary: 'Modulo operator.'
    examples: { '(% num div)', '(mod num div)' }
    description: "Calculate remainder of division by `div`."
  value: func_op ((a, b) -> a % b), num + num

even = Constant.meta
  meta:
    name: 'even'
    summary: 'Check whether val is even.'
    examples: { '(even val [div])' }
    description: "`true` if dividing `val` by `div` has remainder zero.
`div` defaults to 2."
  value: evenodd_op 0

odd = Constant.meta
  meta:
    name: 'odd'
    summary: 'Check whether val is odd.'
    examples: { '(odd val [div])' }
    description: "`true` if dividing `val` by `div` has remainder one.
`div` defaults to 2."
  value: evenodd_op 1

mix = Constant.meta
  meta:
    name: 'mix'
    summary: 'Linearly interpolate.'
    examples: { '(mix a b i)' }
    description: "Interpolate between `a` and `b` using `i` in range 0-1."
  value: func_op ((a, b, i) -> i*b + (1-i)*a), num + num + num

min = Constant.meta
  meta:
    name: 'min'
    summary: "Find the minimum."
    examples: { '(min a b [c…])' }
    description: "Return the lowest of arguments."
  value: func_op math.min, num*0

max = Constant.meta
  meta:
    name: 'max'
    summary: "Find the maximum."
    examples: { '(max a b [c…])' }
    description: "Return the highest of arguments."
  value: func_op math.max, num*0

clamp = Constant.meta
  meta:
    name: 'clamp'
    summary: "Clamp a value to a range."
    examples: { '(clamp min max val)' }
    description: "Returns `min` if `val < min`; `max` if `val > max`; and `val` otherwise."
  value: func_op ((min, max, val) -> math.min max, math.max min, val), num*3

inc = func_def 'inc', 'i', ((i) -> i + 1), "Increment by 1."
dec = func_def 'dec', 'i', ((i) -> i - 1), "Decrement by 1."

cos = func_def 'cos', 'alpha', math.cos, "Cosine function (radians)."
sin = func_def 'sin', 'alpha', math.sin, "Sine function (radians)."
tan = func_def 'tan', 'alpha', math.tan, "Tangent function (radians)."
acos = func_def 'acos', 'cos', math.acos, "Inverse cosine function (radians)."
asin = func_def 'asin', 'sin', math.asin, "Inverse sine function (radians)."
atan = func_def 'atan', 'tan', math.atan, "Inverse tangent function (radians)."
atan2 = func_def 'atan2', 'y x', math.atan2, "Inverse tangent function (two argument version).", num + num
cosh = func_def 'cosh', 'alpha', math.cosh, "Hyperbolic cosine function (radians)."
sinh = func_def 'sinh', 'alpha', math.sinh, "Hyperbolic sine function (radians)."
tanh = func_def 'tanh', 'alpha', math.tanh, "Hyperbolic tangent function (radians)."

floor = func_def 'floor', 'val', math.floor, "Round towards negative infinity."
ceil = func_def 'ceil', 'val', math.ceil, "Round towards positive infinity."
abs = func_def 'abs', 'val', math.abs, "Get the absolute value."

exp = func_def 'exp', 'exp', math.floor, "*e* number raised to a power."
log = func_def 'log', 'val [base]', math.log, "Logarithm with optional base.", num + -num
log10 = func_def 'log10', 'val', math.log10, "Logarithm with base 10."
sqrt = func_def 'sqrt', 'val', math.sqrt, "Square root function."

Constant.meta
  meta:
    name: 'math-simple'
    summary: "Mathematical functions for scalars."
    description: "
All operators are PureOps.
They accept only scalar numbers.
For vectorized operators and matrix multiplication, use [math/][]."

  value:
    :add, '+': add
    :sub, '-': sub
    :mul, '*': mul
    :div, '/': div
    :pow, '^': pow
    :mod, '%': mod

    :even, :odd

    :mix
    :min, :max, :clamp

    :inc, :dec

    pi: Constant.meta
      value: math.pi
      meta: name: 'pi', summary: "The pi constant."

    tau: Constant.meta
      value: math.pi*2
      meta: name: 'tau', summary: "The tau constant."

    huge: Constant.meta
      value: math.huge
      meta: name: 'huge', summary: "Positive infinity constant."

    :sin, :cos, :tan
    :asin, :acos, :atan, :atan2
    :sinh, :cosh, :tanh

    :floor, :ceil, :abs
    :exp, :log, :log10, :sqrt
