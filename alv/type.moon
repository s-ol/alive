-----
--- Type definitions (`type.Type` and implementations).
--
-- @module type
import opairs from require 'alv.util'

shared_shape = (a, b) ->
  for key in pairs a
    return false unless b[key]

  for key in pairs b
    return false unless a[key]

  true

same = (a, b) ->
  return unless shared_shape a, b
  for key, val in pairs a
    return false unless val == b[key]

  true

--- Interface for types.
-- @type Type
class Type
  new: =>

  --- pretty-print a value of this type.
  -- @function pp
  -- @tparam any value
  -- @treturn string

--- Primitive type.
--
-- Implements the `Type` interface.
--
-- @type Primitive
class Primitive
  pp: (value) => tostring value

  __eq: (other) => @type == other.type
  __tostring: => @type

  --- shorthand for number type.
  -- @tfield Primitive num
  @num: @ 'num'

  --- shorthand for string type.
  -- @tfield Primitive str
  @str: @ 'str'

  --- shorthand for symbol type.
  -- @tfield Primitive sym
  @sym: @ 'sym'

  --- shorthand for boolean type.
  -- @tfield Primitive bool
  @bool: @ 'bool'

  --- shorthand for bang type.
  -- @tfield Primitive bang
  @bang: @ 'bang'

  --- shorthand for `Scope` type.
  -- @tfield Primitive scope
  @scope: @ 'scope'

  --- shorthand for `Op` type.
  -- @tfield Primitive op
  @op: @ 'opdef'

  --- shorthand for `FnDef` type.
  -- @tfield Primitive fn
  @fn: @ 'fndef'

  --- shorthand for `Builtin` type.
  -- @tfield Primitive builtin
  @builtin: @ 'builtin'

  --- instantiate a Primitive type.
  -- @classmethod
  -- @tparam string type the typename
  new: (@type) =>

--- Struct/Hashmap type.
--
-- Implements the `Type` interface.
--
-- @type Struct
class Struct
  pp: (value) =>
    inner = table.concat ["#{k}: #{@types[k]\pp v}" for k, v in opairs value], ', '
    "{#{inner}}"

  __eq: (other) => same @types, other.types
  __tostring: =>
    inner = table.concat ["#{k}: #{v}" for k, v in opairs @types], ', '
    "{#{inner}}"

  --- create a new struct type with a subset of keys.
  project: (keys) =>
    types = {}
    for key in *keys
      types[key] = @types[key]
    @@ types

  --- instantiate a Primitive type.
  -- @classmethod
  -- @tparam {string=Type} types
  new: (@types) =>

--- Array type.
--
-- Implements the `Type` interface.
--
-- @type Array
class Array
  pp: (value) =>
    inner = table.concat [@type\pp v for v in *value], ' '
    "[#{inner}]"

  __eq: (other) => @size == other.size and @type == other.type
  __tostring: => "#{@type}[#{@size}]"

  --- instantiate an Array type.
  -- @classmethod
  -- @tparam number size
  -- @tparam Type type
  new: (@size, @type) =>

{
  :Primitive
  :Array
  :Struct
}
