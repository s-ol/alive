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
import SigStream, EvtStream from require 'alv.result'
import Error from require 'alv.error'

unpack or= table.unpack

class PureOp extends Op
--- members.
-- @section members

  --- the argument pattern.
  --
  -- Must resolve to a simple sequence-table (depth 1).
  --
  -- @tfield match.Pattern pattern
  @pattern: nil

  --- the result type.
  -- @tfield type.Type type
  @type: nil

  --- set up inputs for a range of things.
  setup: (inputs) =>
    args = @@pattern\match inputs

    local trigger
    for arg in *args
      if arg.result.metatype == '!'
        assert not trigger, Error 'argument', "pure op can take at most one !-stream."
        trigger = arg

    if trigger
      super for a in *args
        if a == trigger
          Input.hot trigger
        else
          Input.cold a
      @out = EvtStream @@type
    else
      super [Input.hot a for a in *args]
      @out or= SigStream @@type

{
  :PureOp
}
