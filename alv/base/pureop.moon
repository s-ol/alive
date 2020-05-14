----
-- Stateless Operator base for pure functions.
--
-- All arguments can be evt- and val-capable. If one of the arguments is an
-- !-stream, it will be the only `Input.hot`. If there are no !-streams,
-- all inputs are hot. Passing more than one !-stream is an argument error.
--
-- To use `PureOp`, extend the class and set/implement only `pattern`, `type`
-- and `tick`.
-- @classmod PureOp
import Op from require 'alv.base.op'
import Input from require 'alv.base.input'
import Type from require 'alv.type'
import Error from require 'alv.error'
import ancestor, deep_iter, deep_map from require 'alv.util'

unpack or= table.unpack

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
  -- @tparam table args as parsed by `pattern`
  -- @treturn type.Type

  --- set up inputs for a range of things.
  setup: (inputs) =>
    args = @@pattern\match inputs

    local trigger
    for arg in coroutine.wrap -> deep_iter args
      if arg.result.metatype == '!'
        assert not trigger, Error 'argument', "pure op can take at most one !-stream."
        trigger = arg

    typ = if (type @type) == 'table' then @type else @type args
    assert (ancestor typ.__class) == Type, "not a type: #{typ}"

    if trigger
      super deep_map args, (a) ->
        if a == trigger
          Input.hot trigger
        else
          Input.cold a
      -- super for a in *args
      --   if a == trigger
      --     Input.hot trigger
      --   else
      --     Input.cold a
      @out = typ\mk_evt!
    else
      -- super [Input.hot a for a in *args]
      super deep_map args, (a) -> Input.hot a
      @out or= typ\mk_sig!

{
  :PureOp
}
