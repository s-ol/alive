import Struct, Op, PureOp, Constant, Error, const, sig, evt from require 'alv.base'

any = sig! / evt!
key_type = const.str / const.sym

get = Constant.meta
  meta:
    name: 'get'
    summary: "Index into a struct."
    examples: { '(get struct key)' }
    description: "Get the value at `key`.

`key` has to be a constant expression."

  value: class extends PureOp
    pattern: any + key_type
    type: (inputs) =>
      { struct, key } = inputs
      struct\type!\get key.result!

    tick: =>
      { struct, key } = @unwrap_all!
      @out\set struct[key]

set = Constant.meta
  meta:
    name: 'set'
    summary: "Update values in a struct."
    examples: { '(set struct key val)' }
    description: "Set the value for `key` to `val`.

`key` has to be a constant expression. This is a pure op, so at most one of
`struct` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: any + key_type + any
    type: (inputs) =>
      { struct, key, val } = inputs
      type = struct\type!
      expected = type\get key.result!

      if expected ~= val\type!
        msg = string.format "expected value for key '%s' to be %s, not %s",
                            key.result!, expected, val\type!
        error Error 'argument', msg

      type

    tick: =>
      { struct, key, val } = @unwrap_all!

      struct = {k,v for k,v in pairs struct}
      struct[key] = val

      @out\set struct

insert = Constant.meta
  meta:
    name: 'insert'
    summary: "Insert a new value into a struct."
    examples: { '(insert struct key val)' }
    description: "Insert `val` into `struct` at `key`.

`key` has to be a constant expression. This is a pure op, so at most one of
`struct` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: any + key_type + any
    type: (inputs) =>
      { struct, key, val } = inputs
      type = struct\type!
      key = key.result!

      if type.types[key]
        msg = string.format "key '%s' already exists in value of type %s",
                            key, type
        error Error 'argument', msg

      types = {k,v for k,v in pairs type.types}
      types[key] = val\type!
      Struct types

    tick: =>
      { struct, key, val } = @unwrap_all!

      struct = {k,v for k,v in pairs struct}
      struct[key] = val

      @out\set struct

remove = Constant.meta
  meta:
    name: 'remove'
    summary: "Remove values from a struct."
    examples: { '(remove struct key)' }
    description: "Removes the value at index `key` from `struct`.

`key` has to be a constant expression."

  value: class extends PureOp
    pattern: any + key_type
    type: (inputs) =>
      { struct, key } = inputs
      type = struct\type!
      key = key.result!

      -- check key exists
      type\get key

      types = {k,v for k,v in pairs type.types}
      types[key] = nil
      Struct types

    tick: =>
      { struct, key, val } = @unwrap_all!

      struct = {k,v for k,v in pairs struct}
      struct[key] = nil

      @out\set struct

Constant.meta
  meta:
    name: 'struct'
    summary: "Utilities for dealing with structs."

  value:
    :get, :set
    :insert, :remove
