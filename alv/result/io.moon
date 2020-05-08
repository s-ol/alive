----
-- Stream of external side-effects.
--
-- Unlike other `Stream`s, this is not updated/set by an `Op` instace, but is
-- continuously polled for changes by the runtime and may mark itself as
-- *dirty* at any point in time. All runtime execution happens due to IOStream
-- updates, which ripple through the `RTNode` tree.
--
-- @classmod IOStream
import EvtStream from require 'alv.result.evt'

class IOStream extends EvtStream
--- IOStream interface.
--
-- methods that have to be implemented by `IOStream` implementations.
-- @section interface

  --- construct a new IOStream.
  --
  -- Must prepare the instance for `dirty` to be called.
  -- The super-constructor should be called to set `Stream.type`.
  --
  -- @classmethod
  -- @tparam string type the typename of this stream.
  new: (type) => super type

  --- create a mutable copy of this stream.
  --
  -- Used to wrap insulate eval-cycles from each other.
  --
  -- @treturn IOStream
  fork: => @

  --- poll for changes.
  --
  -- Called every frame by the main event loop to update internal state.
  poll: =>

  --- check whether this adapter requires processing.
  --
  -- Must return a boolean indicating whether `Op`s that refer to this instance
  -- via `Input.hot` should be notified (via `Op:tick`). May be called multiple
  -- times. May be called before `poll` on the first frame after construction.
  --
  -- If this is not overriden, the `EvtStream` interface can be used, see
  -- `EvtStream.add`, `EvtStream.unwrap`, and `EvtStream.dirty`.
  --
  -- @function dirty
  -- @treturn bool whether processing is required

  __inherited: (cls) => cls.__base.__tostring or= @__tostring

{
  :IOStream
}
