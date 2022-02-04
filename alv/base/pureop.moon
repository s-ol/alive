----
-- Stateless Operator base for pure functions.
--
-- All arguments can be evt- and val-capable. If one of the arguments is an
-- !-stream, it will be the only `Input.hot`. If there are no !-streams,
-- all inputs are hot. Passing more than one !-stream is an argument error.
--
-- To use `PureOp`, extend the class and set/implement only `pattern`, `type`
-- and `Op:tick`.
-- @classmod PureOp
import Op from require 'alv.base.op'
import Input from require 'alv.base.input'
import Type from require 'alv.type'
import Error from require 'alv.error'
import ancestor, deep_iter, deep_map from require 'alv.util'

unpack or= table.unpack

hot_if_trigger = (trigger) -> (a) ->
  if a == trigger
    return Input.hot a
  Input.cold a

class PureOp extends Op
--- members.
-- @section members

  --- the argument pattern.
  --
  -- Must resolve to a simple sequence-table (depth 1).
  --
  -- @tfield match.Pattern pattern

  --- the result type or a method that returns it.
  --
  -- Can be either a method or just a fixed type.
  --
  -- @function type
  -- @tparam table args as parsed by `pattern`
  -- @treturn type.Type

  --- set up inputs for a range of things.
  --
  -- @tparam {RTNode,...} inputs a sequence of `RTNode`s
  -- @tparam Scope scope (unused)
  -- @tparam[opt] table extra_inputs table of `Input`s to merge into pureop result
  setup: (inputs, scope, extra_inputs={}) =>
    args = @@pattern\match inputs

    local trigger
    for arg in coroutine.wrap -> deep_iter args
      if arg.result.metatype == '!'
        assert not trigger, Error 'argument', "pure op can take at most one !-stream."
        trigger = arg

    typ = if (type @type) == 'function' then @type args else @type
    if typ
      assert (ancestor typ.__class) == Type, "not a type: #{typ}"
      metatype = if trigger then '!' else '~'
      @setup_out metatype, typ

    map_fn = if trigger then hot_if_trigger trigger else Input.hot
    inputs = deep_map args, map_fn
    for k,v in pairs extra_inputs
      inputs[k] = v
    super inputs

{
  :PureOp
}
