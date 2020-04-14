import Op, ValueStream, Error, Input, val from require 'alv.base'
unpack or= table.unpack

class ReduceOp extends Op
  pattern = val.num + val.num*0
  setup: (inputs) =>
    @out or= ValueStream 'num'
    { first, rest } = pattern\match inputs
    super
      first: Input.hot first
      rest: [Input.hot v for v in *rest]

  tick: =>
    { :first, :rest } = @unwrap_all!
    accum = first
    for val in *rest
      accum = @.fn accum, val
    @out\set accum

func_op = (func, pattern) ->
  class extends Op

    setup: (inputs) =>
      @out or= ValueStream 'num'
      params = pattern\match inputs
      super [Input.hot p for p in *params]

    tick: => @out\set func unpack @unwrap_all!

func_def = (name, args, func, summary, pattern) ->
   ValueStream.meta
     meta:
       :name
       :summary
       examples: { "(#{name} #{args})" }
     value: func_op func, pattern or val.num\rep 1, 1

evenodd_op = (remainder) ->
  class extends Op
    pattern = val.num + -val.num
    setup: (inputs) =>
      @out or= ValueStream 'bool'
      { val, div } = pattern\match inputs
      super
        val: Input.hot val
        div: Input.hot div or ValueStream.num 2

    tick: =>
      { :val, :div } = @unwrap_all!
      @out\set (val % div) == remainder

add = ValueStream.meta
  meta:
    name: 'add'
    summary: "Add values."
    examples: { '(+ a b [c…])', '(add a b [c…])' }
    description: "Sum all arguments."
  value: class extends ReduceOp
    fn: (a, b) -> a + b

sub = ValueStream.meta
  meta:
    name: 'sub'
    summary: "Subtract values."
    examples: { '(- a b [c…])', '(sub a b [c…])' }
    description: "Subtract all other arguments from `a`."
  value: class extends ReduceOp
    fn: (a, b) -> a - b

mul = ValueStream.meta
  meta:
    name: 'mul'
    summary: "Multiply values."
    examples: { '(* a b [c…])', '(mul a b [c…])' }
  value: class extends ReduceOp
    fn: (a, b) -> a * b

div = ValueStream.meta
  meta:
    name: 'div'
    summary: "Divide values."
    examples: { '(/ a b [c…])', '(div a b [c…])' }
    description: "Divide `a` by all other arguments."
  value: class extends ReduceOp
    fn: (a, b) -> a / b

pow = ValueStream.meta
  meta:
    name: 'pow'
    summary: "Raise to a power."
    examples: { '(^ base exp)', '(pow base exp' }
    description: "Raise `base` to the power `exp`."
  value: class extends ReduceOp
    fn: (a, b) -> a ^ b

mod = ValueStream.meta
  meta:
    name: 'mod'
    summary: 'Modulo operator.'
    examples: { '(% num div)', '(mod num div)' }
    description: "Calculate remainder of division by `div`."
  value: func_op 2, (a, b) -> a % b

even = ValueStream.meta
  meta:
    name: 'even'
    summary: 'Check whether val is even.'
    examples: { '(even val [div])' }
    description: "`true` if dividing `val` by `div` has remainder zero.
`div` defaults to 2."
  value: evenodd_op 0

odd = ValueStream.meta
  meta:
    name: 'odd'
    summary: 'Check whether val is odd.'
    examples: { '(odd val [div])' }
    description: "`true` if dividing `val` by `div` has remainder one.
`div` defaults to 2."
  value: evenodd_op 1

mix = ValueStream.meta
  meta:
    name: 'mix'
    summary: 'Linearly interpolate.'
    examples: { '(mix a b i)' }
    description: "Interpolate between `a` and `b` using `i` in range 0-1."
  value: func_op 3, (a, b, i) -> i*b + (1-i)*a

min = ValueStream.meta
  meta:
    name: 'min'
    summary: "Find the minimum."
    examples: { '(min a b [c…])' }
    description: "Return the lowest of arguments."
  value: func_op '*', math.min

max = ValueStream.meta
  meta:
    name: 'max'
    summary: "Find the maximum."
    examples: { '(max a b [c…])' }
    description: "Return the highest of arguments."
  value: func_op '*', math.min

cos = func_def 'cos', 'alpha', math.cos, "Cosine function (radians)."
sin = func_def 'sin', 'alpha', math.sin, "Sine function (radians)."
tan = func_def 'tan', 'alpha', math.tan, "Tangent function (radians)."
acos = func_def 'acos', 'cos', math.acos, "Inverse cosine function (radians)."
asin = func_def 'asin', 'sin', math.asin, "Inverse sine function (radians)."
atan = func_def 'atan', 'tan', math.atan, "Inverse tangent function (radians)."
atan2 = func_def 'atan2', 'y x', math.atan2, "Inverse tangent function (two argument version).", val.num\rep(2, 2)
cosh = func_def 'cosh', 'alpha', math.cosh, "Hyperbolic cosine function (radians)."
sinh = func_def 'sinh', 'alpha', math.sinh, "Hyperbolic sine function (radians)."
tanh = func_def 'tanh', 'alpha', math.tanh, "Hyperbolic tangent function (radians)."

floor = func_def 'floor', 'val', math.floor, "Round towards negative infinity."
ceil = func_def 'ceil', 'val', math.ceil, "Round towards positive infinity."
abs = func_def 'abs', 'val', math.abs, "Get the absolute value."

exp = func_def 'exp', 'exp', math.floor, "*e* number raised to a power."
log = func_def 'log', 'val [base]', math.log, "Logarithm with given base.", val.num*2
log10 = func_def 'log10', 'val', math.log10, "Logarithm with base 10."
sqrt = func_def 'sqrt', 'val', math.sqrt, "Square root function."

{
  :add, '+': add
  :sub, '-': sub
  :mul, '*': mul
  :div, '/': div
  :pow, '^': pow
  :mod, '%': mod

  :even, :odd

  :mix
  :min, :max

  pi: with ValueStream.wrap math.pi
    .meta = summary: 'The pi constant.'
  tau: with ValueStream.wrap math.pi*2
    .meta = summary: 'The tau constant.'
  huge: with ValueStream.wrap math.huge
    .meta = summary: 'Positive infinity constant.'

  :sin, :cos, :tan
  :asin, :acos, :atan, :atan2
  :sinh, :cosh, :tanh

  :floor, :ceil, :abs
  :exp, :log, :log10, :sqrt
}
