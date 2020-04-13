----
-- Continuous stream of values.
--
-- Implements the `Stream` and `AST` intefaces.
--
-- @classmod ValueStream
import Stream from require 'alv.stream.base'
import Result from require 'alv.result'
import Error from require 'alv.error'
import scope, base, registry from require 'alv.cycle'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

class ValueStream extends Stream
--- members
-- @section members

  --- return whether this stream was changed in the current tick.
  --
  -- @treturn bool
  dirty: => @updated == registry.Registry.active!.tick

  --- update this stream's value.
  --
  -- Marks this stream as dirty for the remainder of the current tick.
  set: (@value) => @updated = registry.Registry.active!.tick

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
  -- @treturn ValueStream
  fork: =>
    with ValueStream @type, @value, @raw
      .updated = @updated

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  --- compare two values.
  --
  -- Compares two `ValueStream`s by comparing their types and their Lua values.
  __eq: (other) => other.type == @type and other.value == @value

  __tostring: =>
    value = if @meta.name
      @meta.name
    else if 'table' == (type @value) and rawget @value, '__base'
      @value.__name
    else
      tostring @value
    "<#{@@__name} #{@type}: #{value}>"

  --- Stream metatype.
  --
  -- @tfield string metatype
  metatype: 'value'

  --- the type name of this stream.
  --
  -- the following builtin typenames are used:
  --
  -- - `str` - strings, `value` is a Lua string
  -- - `sym` - symbols, `value` is a Lua string
  -- - `num` - numbers, `value` is a Lua number
  -- - `bool` - booleans, `value` is a Lua boolean
  -- - `bang` - trigger signals, `value` is a Lua boolean
  -- - `opdef` - `value` is an `Op` subclass
  -- - `builtin` - `value` is a `Builtin` subclass
  -- - `fndef` - `value` is a `FnDef` instance
  -- - `scope` - `value` is a `Scope` instance
  --
  -- @tfield string type

  --- the wrapped Lua value.
  -- @tfield any value

  --- documentation metadata.
  --
  -- an optional table containing metadata for error messages and
  -- documentation. The following keys are recognized:
  --
  -- - `name`: optional name
  -- - `summary`: single-line description (markdown)
  -- - `examples`: optional list of single-line code examples
  -- - `description`: optional full-text description (markdown)
  --
  -- @tfield ?table meta

--- AST interface
--
-- `ValueStream` implements the `AST` interface.
-- @section ast

  --- evaluate this literal constant.
  --
  -- Throws an error if `type` is not a literal (`num`, `str` or `sym`).
  -- Returns an eval-time const result for `num` and `str`.
  -- Resolves `sym`s in `scope` and returns a reference to them.
  --
  -- @tparam Scope scope the scope to evaluate in
  -- @treturn Result the evaluation result
  eval: (scope) =>
    switch @type
      when 'num', 'str'
        Result value: @
      when 'sym'
        Error.wrap "resolving symbol '#{@value}'", scope\get, @value
      else
        error "cannot evaluate #{@}"

  --- quote this literal constant.
  --
  -- @treturn ValueStream self
  quote: => @

  --- stringify this literal constant.
  --
  -- Throws an error if `raw` is not set.
  --
  -- @treturn string the exact string this stream was parsed from
  stringify: => assert @raw, "stringifying ValueStream that wasn't parsed"

  --- clone this literal constant.
  --
  -- @treturn ValueStream self
  clone: (prefix) => @

--- static functions
-- @section static

  --- construct a new ValueStream.
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
      when 'num' then (match) -> @ 'num', (tonumber match), match
      when 'sym' then (match) -> @ 'sym', match, match
      when 'str' then (match) -> @ 'str', (unescape match), sep .. match .. sep

  --- wrap a Lua value.
  --
  -- Attempts to guess the type and wrap a Lua value.
  --
  -- @tparam any val the value to wrap
  -- @tparam[opt] string name the name of this value (for error logging)
  -- @treturn ValueStream
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
          return ValueStream 'scope', scope.Scope.from_table val
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    ValueStream typ, val

  --- create a constant number.
  -- @tparam number num the number
  -- @treturn ValueStream
  @num: (num) -> ValueStream 'num', num, tostring num

  --- create a constant string.
  -- @tparam string str the string
  -- @treturn ValueStream
  @str: (str) -> ValueStream 'str', str, "'#{str}'"

  --- create a constant symbol.
  -- @tparam string sym the symbol
  -- @treturn ValueStream
  @sym: (sym) -> ValueStream 'sym', sym, sym

  --- create a constant boolean.
  -- @tparam boolean bool the boolean
  -- @treturn ValueStream
  @bool: (bool) -> ValueStream 'bool', bool, tostring bool

  --- wrap and document a value.
  --
  -- wraps `args.value` using `wrap`, then assigns `meta`.
  --
  -- @tparam table args table with keys `value` and `meta`
  -- @treturn ValueStream
  @meta: (args) ->
    with ValueStream.wrap args.value
      .meta = args.meta if args.meta

class LiteralValue extends ValueStream
  eval: => Result value: @

{
  :ValueStream
  :LiteralValue
}
