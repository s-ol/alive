-----
--- Type definitions (`type.Type` and implementations).
--
-- @module type
import opairs from require 'alv.util'
import result from require 'alv.cycle'

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

--- Base class for types.
-- @type Type
class Type
  --- pretty-print a value of this type.
  -- @function pp
  -- @tparam any value
  -- @treturn string

  --- check two values of this type for equality.
  -- @function eq
  -- @tparam any a
  -- @tparam any b
  -- @treturn bool

  --- create a `SigStream` of this type.
  -- @tparam ?any init initial value
  -- @treturn SigStream
  mk_sig: (init) =>
    result.SigStream @, init

  --- create a `EvtStream` of this type.
  -- @treturn EvtStream
  mk_evt: =>
    result.EvtStream @

  --- create a `Constant` of this type.
  -- @tparam any val value
  -- @treturn Constant
  mk_const: (val) =>
    result.Constant @, val

--- Primitive type.
--
-- Extends `Type`.
--
-- @type Primitive
class Primitive extends Type
  pp: (value) =>
    switch @name
      when 'str'
        string.format '%q', value
      else
        tostring value

  eq: (a, b) => a == b

  __eq: (other) => @name == other.name
  __tostring: => @name

  --- instantiate a Primitive type.
  -- @classmethod
  -- @tparam string name the typename
  new: (@name) =>
    assert (type @name) == 'string', "Typename has to be a string: '#{@name}'"

--- Struct/Hashmap type.
--
-- Extends `Type`.
--
-- @type Struct
class Struct extends Type
  pp: (value) =>
    inner = table.concat ["#{k}: #{@types[k]\pp v}" for k, v in opairs value], ' '
    "{#{inner}}"

  eq: (a, b) =>
    for key, type in pairs @types
      if not type\eq a[key], b[key]
        return false
    true

  __eq: (other) => same @types, other.types
  __tostring: =>
    inner = table.concat ["#{k}: #{v}" for k, v in opairs @types], ' '
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
-- Extends `Type`.
--
-- @type Array
class Array extends Type
  pp: (value) =>
    inner = table.concat [@type\pp v for v in *value], ' '
    "[#{inner}]"

  eq: (a, b) =>
    for i=1, @size
      if not @type\eq a[i], b[i]
        return false
    true

  __eq: (other) => @size == other.size and @type == other.type
  __tostring: => "#{@type}[#{@size}]"

  --- instantiate an Array type.
  -- @classmethod
  -- @tparam number size
  -- @tparam Type type
  new: (@size, @type) =>

--- Magic table containing all `Primitive` types.
--
-- When indexed with a string returns a (cached) instance of that type.
--
-- @table T
T = setmetatable {}, __index: (key) =>
  with type = Primitive key
    rawset @, key, type

{
  :T
  :Primitive
  :Array
  :Struct
}
