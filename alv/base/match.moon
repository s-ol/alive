-----
--- Pattern capturing for Op argument parsing.
--
-- There is only one basic buildings block for assembling patterns:
-- `Type`. It can match `SigStream`s and `EvtStream`s depending on its
-- metatype argument and can take an optional type name to match as an argument.
--
-- In addition to this primitive, the following modifiers are available:
-- `Repeat`, `Sequence`, `Choice`, and `Optional`. They can be used directly,
-- but there is also a number of shorthands for assembling patterns quickly:
--
-- - `const()`, `sig()` and `evt()`: Shorthands for `Type('='), Type('~'), Type('!')`
-- - `const.sym`: Shorthand for `Type('=', T.sym)`
-- - `sig.num`: Shorthand for `Type('~', T.num)`
-- - `evt.str`: Shorthand for `Type('!', T.str)`
-- - `pat * 2`: Shorthand for `Repeat(pat, 1, 2)` (1-4 times `pat`)
-- - `pat * 0`: Shorthand for `Repeat(pat, 1, nil)` (1-* times `pat`)
-- - `pat ^ 2`: Shorthand for `Repeat(pat, 0, 2)` (0-4 times `pat`)
-- - `pat ^ 0`: Shorthand for `Repeat(pat, 0, nil)` (0-* times `pat`)
-- - `a + b + … + z`: Shorthand for `Sequence{ a, b, ..., z }`
-- - `a / b / … / z`: Shorthand for `Choice{ a, b, ..., z }`
-- - `-pat`: Shorthand for `Optional(pat)`
--
-- To perform the actual matching, call the `:match` method on a pattern and
-- pass a sequence of `RTNode`s. The method will either return the captured
-- `RTNode`s (or a table structuring them)
--
-- Any ambiguous pattern can be set to 'recall mode' by invoking it.
-- Recalling patterns will memorize the first RTNode they match, and
-- only match further RTNodes of the same type. For example
--
--     arg = (sig.num / sig.str)!
--     pattern = arg + arg
--
-- ...will match either two numbers or two strings, but not one number and one
-- string. Recalling works on `Choice` and `Type` patterns.
--
-- On `Sequence` patterns, a special method `:named` exists. It takes a
-- sequence of keys that are used instead of integers when constructing the
-- capture table:
--
--     pattern = (sig.str + sig.num):named('key', 'value')
--     pattern:match(...)
--     -- returns { {key='a', value=1}, {key='b', value=2}, ...}
--
-- @module base.match
import Error from require 'alv.error'
import T from require 'alv.type'

local Repeat, Sequence, Choice, Optional

class Pattern
  fulltype = (res) -> (tostring res.type) .. res.metatype

  match: (seq) =>
    @reset!
    num, cap = @capture seq, 1
    if num != #seq
      args = table.concat [fulltype arg.result for arg in *seq], ' '
      msg = "couldn't match arguments (#{args}) against pattern #{@}"
      error Error 'argument', msg
    cap

  remember: (key) =>
    return true unless @recall

    @recalled or= key
    @recalled == key

  rep: (min, max) => Repeat @, min, max

  reset: => @recalled = nil

  __call: => @
  __mul: (num) => Repeat @, 1, if num != 0 then num
  __pow: (num) => Repeat @, 0, if num != 0 then num
  __add: (other) => Sequence { @, other }
  __div: (other) => Choice { @, other }
  __unm: => Optional @

  __inherited: (cls) =>
    cls.__base.__call or= @__call
    cls.__base.__mul or= @__mul
    cls.__base.__pow or= @__pow
    cls.__base.__add or= @__add
    cls.__base.__div or= @__div
    cls.__base.__unm or= @__unm

--- Base Result Pattern.
--
-- When instantiated with `type`, only succeeds for `Result`s whose value and
-- meta types match.
--
-- Otherwise, matches Streams based only on `metatype` for the first match, but
-- using both afterwards (recall mode).
--
-- @function Type
-- @tparam string metatype `'~', '!' or '='
-- @tparam ?string type type name
class Type extends Pattern
  new: (@metatype, @type, @recall=false) =>

  casts = { '!!': true, '==': true, '~~': true, '~=': true }
  capture: (seq, i) =>
    return unless seq[i]
    type, mt = seq[i]\type!, seq[i]\metatype!

    if not casts[@metatype .. mt]
      return

    match = if @type then type == @type else @remember type
    if match
      1, seq[i]

  __call: => @@ @metatype, @type, true
  __tostring: => "#{@type or 'any'}#{@metatype}"

--- Repeat a pattern.
--
-- Matches a given `inner` pattern as many times as possible, within the given
-- minimum/maximum counts. Matching this pattern results in a sequence of the
-- individual captures produced by the inner pattern.
--
-- @function Repeat
-- @tparam Pattern inner the original pattern
-- @tparam ?number min minimum amount of repetitions
-- @tparam ?number max maximum amount of repetitions (default infinite)
class Repeat extends Pattern
  new: (@inner, @min, @max) =>

  capture: (seq, i) =>
    total, rep, all = 0, 0, {}
    while true
      num, cap = @inner\capture seq, i+total
      break unless num

      total += num
      rep += 1
      table.insert all, cap

      break if @max and rep >= @max

    return if @min and rep < @min
    return if @max and rep > @max

    total, all

  reset: =>
    @inner\reset!

  __call: =>
    @@ @inner!, @min, @max

  __tostring: =>
    min = @min or '0'
    max = @max or '*'
    "#{@inner}{#{min}-#{max}}"

--- Match multiple patterns in order.
--
-- Matches the inner patterns in order, only succeeds if all of them match.
-- Captures the individual captures produced by the inner patterns in a
-- sequence, or table with keys specified in `keys` or using the `:named(...)`
-- modifier.
--
-- @function Sequence
-- @tparam {Pattern,...} elements the inner patterns
-- @tparam ?{string,...} keys the keys to use when capturing matches
class Sequence extends Pattern
  new: (@elements, @keys) =>

  capture: (seq, i) =>
    take, all = 0, {}
    for key, elem in ipairs @elements
      num, cap = elem\capture seq, i+take
      return unless num

      take += num
      key = @keys[key] if @keys
      all[key] = cap

    take, all

  reset: =>
    for elem in *@elements
      elem\reset!

  named: (...) =>
    @@ [e for e in *@elements], { ... }

  __call: =>
    @@ [e! for e in *@elements], @keys

  __add: (other) =>
    elements = [e for e in *@elements]
    table.insert elements, other
    @@ elements

  __tostring: =>
    core = table.concat [tostring e for e in *@elements], ' '
    "(#{core})"

--- Match one of multiple options.
--
-- Matches using the first matching pattern in `elements` and returns its
-- captured value. Supports recalling the matched subpattern.
--
-- @function Choice
-- @tparam {Pattern,...} elements the inner patterns
-- @tparam ?{string,...} keys the keys to use when capturing matches
class Choice extends Pattern
  new: (@elements, @recall=false) =>

  capture: (seq, i) =>
    for key, elem in ipairs @elements
      num, cap = elem\capture seq, i
      if num and @remember key
        return num, cap

  reset: =>
    super!
    for elem in *@elements
      elem\reset!

  __call: =>
    @@ [e! for e in *@elements], true

  __div: (other) =>
    elements = [e for e in *@elements]
    table.insert elements, other
    @@ elements

  __tostring: =>
    core = table.concat [tostring e for e in *@elements], ' | '
    "(#{core})"

--- Optionally match a pattern.
--
-- Matches using the first matching pattern in `elements` and returns its
-- captured value. Supports recalling the matched subpattern.
--
-- @function Optional
-- @tparam {Pattern,...} elements the inner patterns
-- @tparam ?{string,...} keys the keys to use when capturing matches
class Optional extends Pattern
  new: (@inner) =>

  capture: (seq, i) =>
    num, cap = @inner\capture seq, i
    num or 0, cap

  reset: =>
    @inner\reset!

  __call: =>
    @@ @inner!

  __unm: => @

  __tostring: => "#{@inner}?"

--- `Type` shorthands for matching `Constant`s.
--
-- Call or index with a string to obtain an `Type` instance.
-- Call to obtain a wildcard pattern.
--
--     const.bang, const.str, const.num
--     const['midi/message'], const(Primitive 'midi/message')
--     const()
--
-- @table const
const = setmetatable {}, {
  __index: (key) =>
    with v = Type '=', T[key]
      @[key] = v

  __call: (...) => Type '=', ...
}

--- `Type` shorthands for matching `ValueStream`s and `Constant`s.
--
-- Call or index with a string to obtain a `Type` instance.
-- Call to obtain a wildcard pattern.
--
--     sig.str, sig.num
--     sig['vec3'], sig(T.vec3)
--     sig()
--
-- @table sig
sig = setmetatable {}, {
  __index: (key) =>
    with v = Type '~', T[key]
      @[key] = v

  __call: (...) => Type '~', ...
}

--- `Type` shorthands for matching `EvtStream`s.
--
-- Call or index with a string to obtain an `Type` instance.
-- Call to obtain a wildcard pattern.
--
--     evt.bang, evt.str, evt.num
--     evt['midi/message'], evt(Primitive 'midi/message')
--     evt()
--
-- @table evt
evt = setmetatable {}, {
  __index: (key) =>
    with v = Type '!', T[key]
      @[key] = v

  __call: (...) => Type '!', ...
}

{
  :Type, :Repeat, :Sequence, :Choice, :Optional
  :const, :sig, :evt
}
