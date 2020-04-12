----
-- base Stream interface.
--
-- implemented by `ValueStream`, `EventStream`, and `IOStream`.
--
-- @classmod Stream

class Stream
--- Stream interface.
--
-- Methods that have to be implemented by `Stream` implementations
-- (`ValueStream`, `EventStream`, `IOStream`).
--
-- @section interface

  --- return whether this Stream was changed in the current tick.
  --
  -- @function dirty
  -- @treturn boolean

  --- create a mutable copy of this Stream.
  --
  -- Used to insulate eval-cycles from each other.
  --
  -- @function fork
  -- @treturn Stream

  --- the type name of this Stream's value.
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

  --- construct a new Stream.
  --
  -- @classmethod
  -- @tparam string type the type name
  -- @tparam ?table meta the `meta` table
  new: (@type, @meta={}) =>

{
  :Stream
}
