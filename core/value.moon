----
-- `alive` Value(stream), implements the `AST` inteface.
--
-- @classmod Value
import Result from require 'core.result'
import scope, base, registry from require 'core.cycle'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

class Value
--- members
-- @section members

  --- return whether this Value was changed in the current tick.
  --
  -- @treturn bool
  dirty: => @updated == registry.Registry.active!.tick

  --- update this Value.
  --
  -- Marks this Value as dirty for the remainder of the current tick.
  set: (@value) => @updated = registry.Registry.active!.tick

  --- unwrap to the Lua type.
  --
  -- Asserts `@type == type` if `type` is given.
  --
  -- @tparam[opt] string type the type to check for
  -- @tparam[optchain] string msg message to throw if type don't match
  -- @treturn @value
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    @value

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  --- compare two values.
  --
  -- Compares two `Value`s by comparing their types and their Lua values.
  __eq: (other) => other.type == @type and other.value == @value

  __tostring: =>
    value = if 'table' == (type @value) and rawget @value, '__base' then @value.__name else @value
    "<#{@@__name} #{@type}: #{value}>"

  --- the type name of the Value.
  --
  -- the following builtin typenames are used:
  --
  -- - `str` - strings, `value` is a Lua string
  -- - `sym` - symbols, `value` is a Lua string
  -- - `num` - numbers, `value` is a Lua number
  -- - `bool` - booleans, `value` is a Lua boolean
  -- - `bang` - trigger signals, `value` is a Lua boolean
  -- - `opdef` - `value` is an `Op` subclass
  -- - `builtin` - `value` is an `Action` subclass
  -- - `fndef` - `value` is a `FnDef` instance
  -- - `scope` - `value` is a `Scope` instance
  --
  -- @tfield string type the type name

  --- the wrapped Lua value.
  --
  -- the following builtin typenames are used:
  --
  -- - `str` - strings, `value` is a Lua string
  -- - `sym` - symbols, `value` is a Lua string
  -- - `num` - numbers, `value` is a Lua number
  -- - `bool` - booleans, `value` is a Lua boolean
  -- - `bang` - trigger signals, `value` is a Lua boolean
  -- - `opdef` - `value` is an `Op` subclass
  -- - `builtin` - `value` is an `Action` subclass
  -- - `fndef` - `value` is a `FnDef` instance
  -- - `scope` - `value` is a `Scope` instance
  --
  -- @tfield any value the wrapped value

--- AST interface
--
-- `Value` implements the `AST` interface.
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
        assert (scope\get @value), "undefined reference to symbol '#{@value}'"
      else
        error "cannot evaluate #{@}"

  --- quote this literal constant.
  --
  -- @treturn Value self
  quote: => @

  --- stringify this literal constant.
  --
  -- Throws an error if `raw` is not set.
  --
  -- @treturn string the exact string this Value was parsed from
  stringify: => assert @raw, "stringifying Value that wasn't parsed"

  --- clone this literal constant.
  --
  -- @treturn Value self
  clone: (prefix) => @

--- static functions
-- @section static

  --- construct a new Value.
  --
  -- @classmethod
  -- @tparam string type the type name
  -- @tparam any value the Lua value to be accessed through `unwrap`
  -- @tparam string raw the raw string that resulted in this value. Used by `parsing`.
  new: (@type, @value, @raw) =>

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
  @wrap: (val, name='(unknown)') ->
    typ = switch type val
      when 'number' then 'num'
      when 'string' then 'str'
      when 'table'
        if rawget val, '__base'
          -- a class
          switch ancestor val
            when base.Op then 'opdef'
            when base.Action then 'builtin'
            else
              error "#{name}: cannot wrap class '#{val.__name}'"
        elseif val.__class
          -- an instance
          switch ancestor val.__class
            when scope.Scope then 'scope'
            when base.FnDef then 'fndef'
            when Value
              return val
            else
              error "#{name}: cannot wrap '#{val.__class.__name}' instance"
        else
          -- plain table
          return Value 'scope', scope.Scope.from_table val
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Value typ, val

  --- create a constant number.
  -- @tparam number num the number
  @num: (num) -> Value 'num', num, tostring num

  --- create a constant string.
  -- @tparam string str the string
  @str: (str) -> Value 'str', str, "'#{str}'"

  --- create a constant symbol.
  -- @tparam string sym the symbol
  @sym: (sym) -> Value 'sym', sym, sym

  --- create a constant boolean.
  -- @tparam boolean bool the boolean
  @bool: (bool) -> Value 'bool', bool, tostring bool

{
  :Value
  :load_
}
