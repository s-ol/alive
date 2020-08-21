import Array, Op, PureOp, Constant, Error, const, sig, evt from require 'alv.base'

get = Constant.meta
  meta:
    name: 'get'
    summary: "Index into Arrays."
    examples: { '(get array i)' }
    description: "Get the value at index `i` (starting at 0).

`i` has to be a constant expression."

  value: class extends PureOp
    pattern: (sig! / evt!) + const.num
    type: (inputs) =>
      { array, i } = inputs
      array\type!\get i.result!

    tick: =>
      { array, i } = @unwrap_all!
      @out\set array[i + 1]

set = Constant.meta
  meta:
    name: 'set'
    summary: "Update values in Arrays."
    examples: { '(set array i val)' }
    description: "Set the value for `i` to `val`.

`i` has to be a constant expression. This is a pure op, so at most one of
`array` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: (sig! / evt!) + const.num + (sig! / evt!)
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
    pattern: (sig! / evt!)*1
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
    pattern: (sig! / evt!)*1
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
    summary: "Prepend a new value at the start of an Array."
    examples: { '(prepend array val)' }
    description: "Prepend `val` to `array` at index `0`, moving other values back.

This is a pure op, so at most one of `array` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: (sig! / evt!) + (sig! / evt!)
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
    summary: "Insert new values into Arrays."
    examples: { '(insert array i val)' }
    description: "Insert `val` into `array` at `i`, moving other values back if
necessary.

`i` has to be a constant expression. This is a pure op, so at most one of
`array` and `val` may be a !-stream."

  value: class extends PureOp
    pattern: (sig! / evt!) + const.num + (sig! / evt!)
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
    summary: "Remove values from Arrays."
    examples: { '(remove array i)' }
    description: "Removes the value at index `i` from `array`.

`i` has to be a constant expression."

  value: class extends PureOp
    pattern: (sig! / evt!) + const.num
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
    summary: "Get Array size"
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
    summary: "Concatenate Arrays"
    examples: { '(concat arr1 arr2 [arr3…])' }

  value: class extends PureOp
    pattern: (sig! / evt!)\rep 2
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

{
  :get, :set
  :head, :tail, :prepend
  :insert, :remove

  :size, :concat
}
