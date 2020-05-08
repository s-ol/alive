-- what do i need types for?
--
-- ## implementation side
-- argument specs - without values
-- output specs & output streams
--  - evt outputs are created without values,
--  - val outputs are created *with* values!
--
-- ## language side
-- explicit casting

-- Check whether two tables have all the same,
-- and *only the same* keys.
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

class Type
  __eq: (a, b) ->
    if a.__class == b.__class
      a.__class.__base.__self_eq a, b

  __inherited: (cls) =>
    cls.__base.__self_eq = cls.__base.__eq
    cls.__base.__eq = @__eq

class Primitive extends Type
  new: (@type) =>

  pp: (value) => tostring value

  __eq: (other) => @type == other.type
  __tostring: => @type

class Struct extends Type
  new: (@types) =>

  --- create a new struct with a selection of keys
  project: (keys) =>
    types = {}
    for key in *keys
      types[key] = @types[key]
    @@ types

  pp: (value) =>
    inner = table.concat ["#{k}: #{@types[k]\pp v}" for k, v in pairs value], ', '
    "{#{inner}}"

  __eq: (other) => same @types, other.types
  __tostring: =>
    inner = table.concat ["#{k}: #{v}" for k, v in pairs @types], ', '
    "{#{inner}}"

class Array extends Type
  new: (@size, @type) =>

  pp: (value) =>
    inner = table.concat [@type\pp v for v in *value], ' '
    "[#{inner}]"

  __eq: (other) => @size == other.size and @type == other.type
  __tostring: => "#{@type}[#{@size}]"

"
bool = Primitive 'bool'
num = Primitive 'num'
str = Primitive 'str'

vec3 = Array 3, num
noteevt = Struct { note: str, dur: num }

assert.is.equal 'num[3]', tostring vec3
assert.is.equal '{dur: num, note: str}', tostring noteevt

assert.is.equal vec3 == Array 3, num
assert.not.equal vec3, Array 3, str
assert.is.equal noteevt, Struct { oct: num, note: str, dur: num }
assert.not.equal noteevt, Struct { oct: num, note: str, dur: str }

print Constant bool, false
print SigStream vec3, { 0.5, 0.3, 0.7 }
print EvtStream noteevt
"

{
  :Primitive
  :Array
  :Struct
}
