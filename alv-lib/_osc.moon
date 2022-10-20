import new_message from require 'losc'
import opairs from require 'alv.util'
import T, Array, Struct from require 'alv.base'

add_item = (message, type, val, use_arrays=false) ->
  switch type.__class
    when Array
      message\add '[' if use_arrays
      for i=1,type.size
        add_item message, type.type, val[i], use_arrays
      message\add ']' if use_arrays
    when Struct
      message\add '[' if use_arrays
      for key, subtype in opairs type.types
        message\add 's', key
        add_item message, subtype, val[key], use_arrays
      message\add ']' if use_arrays
    else
      ts = switch type
        when T.num then 'f'
        when T.str, T.sym then 's'
        when T.bool, T.bang
          if val then 'T' else 'F'
        else
          error "unknown primitive type"
      message\add ts, val

{
  :new_message
  :add_item
}
