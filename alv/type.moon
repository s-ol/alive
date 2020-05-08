-----
--- Type definition classes
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

class Primitive
  new: (@type) =>

  pp: (value) => tostring value

  __eq: (other) => @type == other.type
  __tostring: => @type

class Struct
  new: (@types) =>

  --- create a new struct with a selection of keys
  project: (keys) =>
    types = {}
    for key in *keys
      types[key] = @types[key]
    @@ types

  pp: (value) =>
    inner = table.concat ["#{k}: #{@types[k]\pp v}" for k, v in opairs value], ', '
    "{#{inner}}"

  __eq: (other) => same @types, other.types
  __tostring: =>
    inner = table.concat ["#{k}: #{v}" for k, v in opairs @types], ', '
    "{#{inner}}"

class Array
  new: (@size, @type) =>

  pp: (value) =>
    inner = table.concat [@type\pp v for v in *value], ' '
    "[#{inner}]"

  __eq: (other) => @size == other.size and @type == other.type
  __tostring: => "#{@type}[#{@size}]"

{
  :Primitive
  :Array
  :Struct
}
