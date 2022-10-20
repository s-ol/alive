import PureOp, RTNode, Constant, Error, T, Array, any from require 'alv.base'
unpack or= table.unpack

--- (recursively) wrap/repeat a scalar value to match a (nested) array type.
--
-- For example `expand_to (Array 3, Array 4, T.num), 2` will return
-- `[[2 2 2 2] [2 2 2 2] [2 2 2 2]]`.
expand_to = (want, have, val) ->
  return val if want == have

  return for key, inner in want\iter_keys!
    expand_to inner, have, val

--- apply fn componentwise
deep_apply = (fn, type, args) ->
  return fn args unless type.iter_keys

  return for key, inner in type\iter_keys!
    deep_apply fn, inner, [arg[key] for arg in *args]

is_vec = (type) -> type.__class == Array and type.type == T.num
is_mat = (type) -> type.__class == Array and type.type.__class == Array

--- return a function that runs `expand_to` on all arguments
--
-- @treturn function
deep_apply_fn = (_func, types) ->
  func = (args) -> _func unpack args

  result_type = nil
  for type in *types
    continue if type == T.num

    result_type or= type
    assert type == result_type

  -- all scalars, don't expand
  if not result_type
    return T.num, func

  -- at least one non-scalar
  result_type, (args) ->
    -- expand all arguments
    expanded = for i, arg in ipairs args
      if types[i] != result_type
        expand_to result_type, types[i], arg
      else
        arg

    deep_apply func, result_type, expanded


multiply_mat = (ltype, rtype, lval, rval) ->
  return for i = 1, ltype.size
    for j = 1, rtype.type.size
      accum = 0
      for k = 1, rtype.size
        accum += lval[i][k] * rval[k][j]
      accum

apply_fn_linalg = (types) ->
  result = types[1]
  fns = {}

  for i=2, #types
    local nextres
    ltype = result
    rtype = types[i]

    lvec, rvec = (is_vec ltype), (is_vec rtype)

    fn = if (lvec and rvec) or ltype == T.num or rtype == T.num
      -- componentwise mult
      nextres = if lvec or (is_mat ltype) then ltype else rtype
      (lval, rval) ->
        lval = expand_to nextres, ltype, lval
        rval = expand_to nextres, rtype, rval
        deep_apply ((args) -> args[1] * args[2]), nextres, { lval, rval }
    else
      -- matrix/vector multiplication or matrix/matrix multiplication
      if lvec
        nextres = ltype
        ltype = Array 1, ltype
      else if rvec
        nextres = rtype
        rtype = Array rtype.size, Array 1, rtype.type if rvec
      else
        nextres = Array ltype.size, Array rtype.type.size, T.num

      assert ltype.type.size == rtype.size

      (lval, rval) ->
        lval = {lval} if lvec
        rval = [{ v } for v in *rval] if rvec
        res = multiply_mat ltype, rtype, lval, rval
        if rvec
          [v[1] for v in *res]
        else if lvec
          res[1]
        else
          res

    result = nextres
    table.insert fns, fn

  result, (args) ->
    accum = args[1]
    for i, fn in ipairs fns
      accum = fn accum, args[i + 1]
    accum

num = any.num / any!!

reduce_fn = (fn) ->
  (accum, ...) ->
    for i=1, select '#', ...
      accum = fn accum, select i, ...
    accum

func_op = (func, pattern) ->
  class extends PureOp
    pattern: pattern
    type: (inputs) =>
      types = [input\type! for input in *inputs]
      result, @func = deep_apply_fn func, types
      assert (is_vec result) or (is_mat result) or (result == T.num),
        Error 'argument', "expected matrices, vectors or numbers"
      result

    tick: => @out\set @.func @unwrap_all!

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
  value: class extends func_op (reduce_fn (a, b) -> a - b), num*0
    setup: (inputs, ...) =>
      if #inputs == 1
        table.insert inputs, 1, RTNode result: Constant.num 0
      super inputs, ...

mul = Constant.meta
  meta:
    name: 'mul'
    summary: "Multiply scalars, vectors and matrices."
    examples: { '(* a b [c…])', '(mul a b [c…])' }
    description: "Multiplies all arguments.

For every pair of arguments, from left to right:

- If either argument is a scalar, or both are vectors, multiply componentwise.
- If either argument is a matrix and the other is a vector, apply the matrix transformation.
  - `(* num[L][M] num[M]) → num[L]` (forward transform)
  - `(* num[M] num[M][N]) → num[N]` (reverse transform)
- If both arguments are matrices, multiply them using matrix multiplication.
  - `(* num[L][M] num[M][N]) → num[M][N]`"
  value: class extends PureOp
    pattern: any!\rep 2, nil

    type: (inputs) =>
      types = [input\type! for input in *inputs]
      result, @func = apply_fn_linalg types
      assert (is_vec result) or (is_mat result) or (result == T.num),
        Error 'argument', "expected matrices, vectors or numbers"
      result

    tick: => @out\set @.func @unwrap_all!

div = Constant.meta
  meta:
    name: 'div'
    summary: "Divide values."
    examples: { '(/ a b [c…])', '(div a b [c…])' }
    description: "Divide `a` by all other arguments."
  value: func_op (reduce_fn (a, b) -> a / b), num\rep 2, nil
  -- @TODO: block matrix-matrix division

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
    name: 'math'
    summary: "Mathematical functions."
    description: "
This module is exactly like [math-simple/][], except that the operators
also work componentwise with vectors (`num[X]`) and matrices (`num[X][Y]`).
All operators are PureOps.

    (+ 1 2 3) #(<num= 6>)
    (+ (array 1 2) (array 3 4)) #(<num[2]= [4 6]>)

The arguments for an operator generally have to be of the same type.
However it is also okay to pass in scalar numbers together with a different type.
The scalars will be repeated as necessary to fit the shape of other arguments:

    (* (array (array 1 2) (array 3 4))
       2)
    #(<num[2][2]= [[2 4] [6 8]]>)

The [mul][:math/mul:] (`*`) operator is the only exception to this,
as it handles matrix-matrix and matrix-vector multiplication according to linear algebra.
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
