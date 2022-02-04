import Array, Op, PureOp, Builtin, RTNode, Constant, Error, const, any, T from require 'alv.base'
import Cell, Tag, Dummy from require 'alv.ast'
builtins = require 'alv.builtins'

unpack or= table.unpack

get = Constant.meta
  meta:
    name: 'get'
    summary: "Index into an array."
    examples: { '(get array i)' }
    description: "Get the value at index `i` (starting at 0).

`i` has to be a constant expression."

  value: class extends PureOp
    pattern: any! + const.num
    type: (inputs) =>
      { array, i } = inputs
      array\type!\get i.result!

    tick: =>
      { array, i } = @unwrap_all!
      @out\set array[i + 1]

set = Constant.meta
  meta:
    name: 'set'
    summary: "Update a value in an array."
    examples: { '(set array i val)' }
    description: "Set the value for `i` to `val`.

`i` has to be a constant expression. This is a pure op, so at most one of
`array` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: any! + const.num + any!
    type: (inputs) =>
      { array, i, val } = inputs
      type = array\type!
      expected = type\get i.result!

      if expected ~= val\type!
        msg = string.format "expected value of type %s, not %s",
                            expected, val\type!
        error Error 'argument', msg

      type

    tick: =>
      { array, key, val } = @unwrap_all!

      array = [v for v in *array]
      array[key + 1] = val

      @out\set array

head = Constant.meta
  meta:
    name: 'head'
    summary: "Get the first element from an array."
    examples: { '(head array)' }

  value: class extends PureOp
    pattern: any!*1
    type: (inputs) =>
      type = inputs[1]\type!

      assert type.__class == Array, Error 'argument', "expected an Array"
      assert type.size > 0, Error 'argument', "cannot get head of empty Array"

      type.type

    tick: =>
      { array } = @unwrap_all!
      @out\set array[1]

tail = Constant.meta
  meta:
    name: 'tail'
    summary: "Get everything except the first element from an array."
    examples: { '(tail array)' }

  value: class extends PureOp
    pattern: any!*1
    type: (inputs) =>
      type = inputs[1]\type!

      assert type.__class == Array, Error 'argument', "expected an Array"
      assert type.size > 0, Error 'argument', "cannot get tail of empty Array"

      Array type.size - 1, type.type

    tick: =>
      { array } = @unwrap_all!
      @out\set [v for v in *array[2,]]

prepend = Constant.meta
  meta:
    name: 'prepend'
    summary: "Prepend a new value at the start of an array."
    examples: { '(prepend array val)' }
    description: "Prepend `val` to `array` at index `0`, moving other values back.

This is a pure op, so at most one of `array` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: any! + any!
    type: (inputs) =>
      { array, val } = inputs
      type = array\type!

      if val\type! ~= type.type
        msg = string.format "expected value of type %s, not %s",
                            type.type, val\type!
        error Error 'argument', msg

      Array type.size + 1, type.type

    tick: =>
      { array, val } = @unwrap_all!

      array = [v for v in *array]
      table.insert array, 1, val

      @out\set array

insert = Constant.meta
  meta:
    name: 'insert'
    summary: "Insert a new value into an array."
    examples: { '(insert array i val)' }
    description: "Insert `val` into `array` at `i`, moving other values back if
necessary.

`i` has to be a constant expression. This is a pure op, so at most one of
`array` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: any! + const.num + any!
    type: (inputs) =>
      { array, i, val } = inputs
      type = array\type!
      i = i.result!

      if i > type.size or i < 0
        error Error 'argument', "index '#{i}' out of range!"
      if val\type! ~= type.type
        msg = string.format "expected value of type %s, not %s",
                            type.type, val\type!
        error Error 'argument', msg

      Array type.size + 1, type.type

    tick: =>
      { array, i, val } = @unwrap_all!

      array = [v for v in *array]
      table.insert array, i + 1, val

      @out\set array

remove = Constant.meta
  meta:
    name: 'remove'
    summary: "Remove a value from an Array."
    examples: { '(remove array i)' }
    description: "Removes the value at index `i` from `array`.

`i` has to be a constant expression."

  value: class extends PureOp
    pattern: any! + const.num
    type: (inputs) =>
      { array, i } = inputs
      type = array\type!

      -- check index range
      type\get i.result!

      Array type.size - 1, type.type

    tick: =>
      { array, i, val } = @unwrap_all!

      array = [v for v in *array]
      table.remove array, i + 1

      @out\set array

size = Constant.meta
  meta:
    name: 'size'
    summary: "Get the size of an array."
    examples: { '(size array)' }

  value: class extends Op
    setup: (inputs) =>
      super {}

      assert #inputs == 1, Error 'argument', "expected exactly one argument"
      type = inputs[1]\type!
      assert type.__class == Array, Error 'argument', "expected an Array"

      @out = Constant.num type.size

concat = Constant.meta
  meta:
    name: 'concat'
    summary: "Concatenate Arrays."
    examples: { '(concat arr1 arr2 [arr3…])' }

  value: class extends PureOp
    pattern: any!\rep 2
    type: (inputs) =>
      size = 0
      type = inputs[1]\type!.type

      for input in *inputs
        array = input\type!

        if array.type ~= type
          msg = string.format "Cannot concatenate different arrays %s, %s",
                inputs[1]\type!, array
          error Error 'argument', msg

        size += array.size

      Array size, type

    tick: =>
      arrays = @unwrap_all!
      out = {}

      for array in *arrays
        for val in *array
          table.insert out, val

      @out\set out

array_constr = builtins!\get('array').result
map = Constant.meta
  meta:
    name: 'map'
    summary: "Apply an function to each value in an array."
    examples: { '(map array fn)' }
    description: "
Invokes `fn` once for each element in `array` and returns an array of the results.
`fn` must take one argument and return the same type consistently."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 2, "'map' takes exactly two arguments"
      tail = [L\push t\eval, scope for t in *tail]
      { array, fn } = tail

      fndef = fn.result
      assert fn\type! == T.fndef, "fn has to be a fndef"
      array_type = array\type!
      assert array_type.__class == Array, Error 'argument', "expected an Array"

      invocations = for i=1, array_type.size
        tag_o = @tag\clone Tag.parse tostring i
        tag_i = @tag\clone tag_o
        Cell tag_o, {
          with Constant.literal T.fndef, fndef!, 'fn'
            .meta = fndef.meta
          Cell tag_i, {
            Constant.literal T.opdef, get!, 'get'
            Constant.literal array_type, array.result!, 'array'
            Constant.num i-1
          }
        }

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, {
        Constant.literal T.opdef, array_constr, 'array'
        unpack invocations
      }
      super inner\eval scope


Constant.meta
  meta:
    name: 'array'
    summary: "Utilities for dealing with arrays."

  value:
    :get, :set
    :head, :tail, :prepend
    :insert, :remove
    :map

    :size, :concat
