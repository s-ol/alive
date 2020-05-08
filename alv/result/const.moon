----
-- Constant Value.
--
-- Implements the `Stream` and `AST` inteface.
--
-- @classmod Constant
import Stream from require 'alv.result.base'
import RTNode from require 'alv.rtnode'
import Error from require 'alv.error'
import scope, base from require 'alv.cycle'
import Primitive from require 'alv.types'

num = Primitive 'num'
str = Primitive 'str'
sym = Primitive 'sym'
bool = Primitive 'bool'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

class Constant extends Stream
  --- Whether this Result is dirty.
  --
  -- @tresult bool always `false`.
  dirty: => false

  --- unwrap to the Lua type.
  --
  -- Asserts `@type == type` if `type` is given.
  --
  -- @tparam[opt] string type the type to check for
  -- @tparam[optchain] string msg message to throw if type don't match
  -- @treturn any `value`
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    @value

  --- create a mutable copy of this stream.
  --
  -- Used to insulate eval-cycles from each other.
  --
  -- @treturn Constant
  fork: => @

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  --- compare two values.
  --
  -- Compares two `SigStream`s by comparing their types and their Lua values.
  __eq: (other) => other.type == @type and other.value == @value

  --- Stream metatype.
  --
  -- @tfield string metatype (`=`)
  metatype: '='

--- AST interface
--
-- `SignStream` implements the `AST` interface.
-- @section ast

  --- evaluate this literal constant.
  --
  -- Throws an error if `type` is not a literal (`num`, `str` or `sym`).
  -- Returns an eval-time const result for `num` and `str`.
  -- Resolves `sym`s in `scope` and returns a reference to them.
  --
  -- @tparam Scope scope the scope to evaluate in
  -- @treturn RTNode the evaluation result
  eval: (scope) =>
    return RTNode value: @ if @literal

    switch @type
      when num, str
        RTNode value: @
      when sym
        Error.wrap "resolving symbol '#{@value}'", scope\get, @value
      else
        error "cannot evaluate #{@}"

  --- stringify this literal constant.
  --
  -- Throws an error if `raw` is not set.
  --
  -- @treturn string the exact string this stream was parsed from
  stringify: => @raw

  --- clone this literal constant.
  --
  -- @treturn SignStream self
  clone: (prefix) => @

--- static functions
-- @section static

  --- construct a new Constant.
  --
  -- @classmethod
  -- @tparam string type the type name
  -- @tparam any value the Lua value to be accessed through `unwrap`
  -- @tparam string raw the raw string that resulted in this value. Used by `parsing`.
  new: (type, @value, @raw) => super type

  unescape = (str) -> str\gsub '\\([\'"\\])', '%1'
  --- create a capture-function (for parsing with Lpeg).
  --
  -- @tparam string type the type name (one of `num`, `sym` or `str`)
  -- @tparam string sep the seperator char (only for `str`)
  @parse: (type, sep) =>
    switch type
      when 'num' then (match) -> @ num, (tonumber match), match
      when 'sym' then (match) -> @ sym, match, match
      when 'str' then (match) -> @ str, (unescape match), sep .. match .. sep

  --- wrap a Lua value.
  --
  -- Attempts to guess the type and wrap a Lua value.
  --
  -- @tparam any val the value to wrap
  -- @tparam[opt] string name the name of this value (for error logging)
  -- @treturn Constant
  @wrap: (val, name='(unknown)') ->
    typ = switch type val
      when 'number' then 'num'
      when 'string' then 'str'
      when 'table'
        if rawget val, '__base'
          -- a class
          switch ancestor val
            when base.Op then 'opdef'
            when base.Builtin then 'builtin'
            else
              error "#{name}: cannot wrap class '#{val.__name}'"
        elseif val.__class
          -- an instance
          switch ancestor val.__class
            when scope.Scope then 'scope'
            when base.FnDef then 'fndef'
            when Stream then return val
            else
              error "#{name}: cannot wrap '#{val.__class.__name}' instance"
        else
          -- plain table
          val = scope.Scope.from_table val
          'scope'
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Constant (Primitive typ), val

  --- create a constant number.
  -- @tparam number val the number
  -- @treturn Constant
  @num: (val) -> Constant num, val, tostring val

  --- create a constant string.
  -- @tparam string val the string
  -- @treturn Constant
  @str: (val) -> Constant str, val, "'#{val}'"

  --- create a constant symbol.
  -- @tparam string val the symbol
  -- @treturn Constant
  @sym: (val) -> Constant sym, val, val

  --- create a constant boolean.
  -- @tparam boolean val the boolean
  -- @treturn Constant
  @bool: (val) -> Constant bool, val, tostring val

  --- create a forced-literal Constant.
  --
  -- For internal use in `Builtin`s only.
  --
  -- @treturn Constant
  @literal: (...) ->
    with Constant ...
      .literal = true

  --- wrap and document a value.
  --
  -- wraps `args.value` using `wrap`, then assigns `meta`.
  --
  -- @tparam table args table with keys `value` and `meta`
  -- @treturn Constant
  @meta: (args) ->
    with Constant.wrap args.value
      .meta = args.meta if args.meta

{
  :Constant
}
