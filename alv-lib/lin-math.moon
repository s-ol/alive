import PureOp, Constant, T, any from require 'alv.base'
unpack or= table.unpack

---
-- (recursively) wrap/repeat a scalar value to match a (nested) array type.
--
-- For example `expand_to (Array 3, Array 4, T.num), 2` will return
-- `[[2 2 2 2] [2 2 2 2] [2 2 2 2]]`.
expand_to = (type, scalar) ->
  return scalar unless type.iter_keys

  return for key, inner in type\iter_keys!
    expand_to inner, scalar

deep_apply = (fn, type, args) ->
  return fn args unless type.iter_keys

  return for key, inner in type\iter_keys!
    deep_apply fn, inner, [arg[key] for arg in *args]

--- return a function that runs `expand_to` on all arguments
--
-- @treturn function
expand_all_fn = (types) ->
  result_type = nil
  for type in *types
    continue if type == T.num

    result_type or= type
    assert type == result_type

  -- all scalars, don't expand
  if not result_type
    return T.num, (args) -> args

  -- at least one non-scalar
  result_type, (args) ->
    -- expand all arguments
    return for i, arg in ipairs args
      if types[i] != result_type
        expand_to result_type, arg
      else
        arg

num = any!! / any.num

reduce_fn = (fn) ->
  (accum, ...) ->
    for i=1, select '#', ...
      accum = fn accum, select i, ...
    accum

func_op = (_func, pattern) ->
  func = (args) -> _func unpack args

  class extends PureOp
    pattern: pattern
    type: (inputs) =>
      types = [input\type! for input in *inputs]
      result, @expand = expand_all_fn types
      result

    tick: =>
      @out\set deep_apply func, @out.type, @.expand @unwrap_all!

func_def = (name, args, func, summary, pattern) ->
   Constant.meta
     meta:
       :name
       :summary
       examples: { "(#{name} #{args})" }
     value: func_op func, pattern or num\rep 1, 1

evenodd_op = (remainder) ->
  class extends PureOp
    pattern: T.num + -T.num
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
  value: func_op (reduce_fn (a, b) -> a + b), num\rep 2, nil

sub = Constant.meta
  meta:
    name: 'sub'
    summary: "Subtract values."
    examples: { '(- a b [c…])', '(sub a b [c…])' }
    description: "Subtract all other arguments from `a`."
  value: func_op (reduce_fn (a, b) -> a - b), num\rep 2, nil

mul = Constant.meta
  meta:
    name: 'mul'
    summary: "Multiply values."
    examples: { '(* a b [c…])', '(mul a b [c…])' }
  value: func_op (reduce_fn (a, b) -> a * b), num\rep 2, nil

div = Constant.meta
  meta:
    name: 'div'
    summary: "Divide values."
    examples: { '(/ a b [c…])', '(div a b [c…])' }
    description: "Divide `a` by all other arguments."
  value: func_op (reduce_fn (a, b) -> a / b), num\rep 2, nil

pow = Constant.meta
  meta:
    name: 'pow'
    summary: "Raise to a power."
    examples: { '(^ base exp)', '(pow base exp' }
    description: "Raise `base` to the power `exp`."
  value: func_op (reduce_fn (a, b) -> a ^ b), num\rep 2, nil

mod = Constant.meta
  meta:
    name: 'mod'
    summary: 'Modulo operator.'
    examples: { '(% num div)', '(mod num div)' }
    description: "Calculate remainder of division by `div`."
  value: func_op ((a, b) -> a % b), num + num

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
    name: 'math'
    summary: "Mathematical functions, expanded to vectors and matrices."
    description: "
These functions are like the ones in [math/][:],
except that they can also operate componentwise on (nested) arrays of numbers.

    (+ 1 2 3) #(<num= 6>)
    (+ (array 1 2) (array 3 4)) #(<num[2]= [4 6]>)

The arguments for an operator generally have to be of the same type.
However it is also okay to pass in scalar numbers together with a different type.
The scalars will be repeated as necessary to fit the shape of other arguments:

    (* (array (array 1 2) (array 3 4))
       2)
    #(<num[2][2]= [[2 4] [6 8]]>)
"

  value:
    :add, '+': add
    :sub, '-': sub
    :mul, '*': mul
    :div, '/': div
    :pow, '^': pow
    :mod, '%': mod

    :even, :odd

    :mix
    :min, :max

    :inc, :dec

    pi: Constant.meta
      value: math.pi
      meta: summary: 'The pi constant.'

    tau: Constant.meta
      value: math.pi*2
      meta: summary: 'The tau constant.'

    huge: Constant.meta
      value: math.huge
      meta: summary: 'Positive infinity constant.'

    :sin, :cos, :tan
    :asin, :acos, :atan, :atan2
    :sinh, :cosh, :tanh

    :floor, :ceil, :abs
    :exp, :log, :log10, :sqrt
