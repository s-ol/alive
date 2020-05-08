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
-- - `val()` and `evt()`: Shorthands for `Type('value')` and `Type('event')`
-- - `val.num`: Shorthand for `Type('value', 'num')`
-- - `evt.str`: Shorthand for `Type('event', 'str')`
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
--     arg = (val.num / val.str)!
--     pattern = arg + arg
--
-- ...will match either two numbers or two strings, but not one number and one
-- string. Recalling works on `Choice` and `Type` patterns. `Type` patterns
-- without a type (`val!` and `evt!`) always behave like this.
--
-- On `Sequence` patterns, a special method `:named` exists. It takes a
-- sequence of keys that are used instead of integers when constructing the
-- capture table:
--
--     pattern = (val.str + val.num):named('key', 'value')
--     pattern:match(...)
--     -- returns { {key='a', value=1}, {key='b', value=2}, ...}
--
-- @module base.match
import Error from require 'alv.error'
import Primitive from require 'alv.type'

local Repeat, Sequence, Choice, Optional

typestr = (result) -> tostring result.value

class Pattern
  match: (seq) =>
    @reset!
    num, cap = @capture seq, 1
    if num != #seq
      args = table.concat [typestr arg for arg in *seq], ' '
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

--- Base Stream Pattern.
--
-- When instantiated with `type`, only succeeds for `Stream`s whose value and
-- meta types match.
--
-- Otherwise, matches Streams based only on `metatype` for the first match, but
-- using both afterwards (recall mode).
--
-- @function Stream
-- @tparam string metatype "value" or "event"
-- @tparam ?string type type name
class Type extends Pattern
  new: (@metatype, @type) =>
    @recall = not @type

  capture: (seq, i) =>
    return unless seq[i]
    type, mt = seq[i]\type!, seq[i]\metatype!
    if @metatype == 'event'
      return unless mt == '!'
    else
      return if mt == '!'

    match = if @type then type == @type else @remember type
    if match
      1, seq[i]

  __tostring: =>
    str = tostring @type or @metatype
    str ..= '!' if @metatype == 'event'
    str

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
    take, all = 0, {}
    while true
      num, cap = @inner\capture seq, i+take
      break unless num

      take += num
      table.insert all, cap

      break if @max and take >= @max

    return if @min and take < @min
    return if @max and take > @max

    take, all

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
    @@ [e! for e in *@elements]

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

--- `Value` shorthands.
--
-- Call or index with a string to obtain a `Type` instance.
-- Call to obtain a wildcard pattern.
--
--     val.str, val.num
--     val['vec3'], val('vec3')
--     val()
--
-- @table val
val = setmetatable {}, {
  __index: (key) =>
    with v = Type 'value', Primitive key
      @[key] = v

  __call: (...) => Type 'value', ...
}

--- `Event` shorthands.
--
-- Call or index with a string to obtain an `Type` instance.
-- Call to obtain a wildcard pattern.
--
--     evt.bang, evt.str, evt.num
--     evt['midi/message'], evt('midi/message')
--     evt()
--
-- @table evt
evt = setmetatable {}, {
  __index: (key) =>
    with v = Type 'event', Primitive key
      @[key] = v

  __call: (...) => Type 'event', ...
}

{
  :Type, :Repeat, :Sequence, :Choice, :Optional
  :val, :evt
}
