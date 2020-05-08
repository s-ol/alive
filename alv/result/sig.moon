----
-- Continuous stream of values.
--
-- @classmod SigStream
import Stream from require 'alv.result.base'
import Primitive from require 'alv.types'

class SigStream extends Stream
--- members
-- @section members

  --- return whether this stream was changed in the current tick.
  --
  -- @treturn bool
  dirty: => @updated == COPILOT.T

  --- update this stream's value.
  --
  -- Marks this stream as dirty for the remainder of the current tick.
  set: (value) =>
    if value != @value
      @value = value
      @updated = COPILOT.T

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
  -- @treturn SigStream
  fork: =>
    with @@ @type, @value
      .updated = @updated

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  --- compare two values.
  --
  -- Compares two `SigStream`s by comparing their types and their Lua values.
  __eq: (other) => other.type == @type and other.value == @value

  --- Stream metatype.
  --
  -- @tfield string metatype (`~`)
  metatype: '~'

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

--- static functions
-- @section static

  --- construct a new SigStream.
  --
  -- @classmethod
  -- @tparam string type the type name
  -- @tparam any value the Lua value to be accessed through `unwrap`
  new: (type, @value) => super type

  --- create a number stream.
  -- @tparam number val the number
  -- @treturn SigStream
  @num: (val) -> SigStream Primitive'num', val

  --- create a string stream.
  -- @tparam string val the string
  -- @treturn SigStream
  @str: (val) -> SigStream Primitive'str', val

  --- create a symbol stream.
  -- @tparam string val the symbol
  -- @treturn symbol
  @sym: (val) -> SigStream Primitive'sym', val

  --- create a boolean stream.
  -- @tparam boolean val the boolean
  -- @treturn SigStream
  @bool: (val) -> SigStream Primitive'bool', val

{
  :SigStream
}
