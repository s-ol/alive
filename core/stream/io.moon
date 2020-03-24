----
-- Stream of external side-effects.
--
-- Unlike other `Stream`s, this is not updated/set by an `Op` instace, but is
-- continuously polled for changes by the runtime and may mark itself as
-- *dirty* at any point in time. All runtime execution happens due to IOStream
-- updates, which ripple through the `Result` tree.
--
-- @classmod IOStream
import EventStream from require 'core.stream.event'

class IOStream extends EventStream
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

  --- poll for changes.
  --
  -- Called every frame by the main event loop to update internal state.
  tick: =>

  --- check whether this adapter requires processing.
  --
  -- Must return a boolean indicating whether `Op`s that refer to this instance
  -- via `Input.io` should be notified (via `Op:tick`). May be called multiple
  -- times. May be called before `tick` on the first frame after construction.
  --
  -- If this is not overrided, the `EventStream` interface can be used, see
  -- `EventStream.add`, `EventStream.unwrap`, and `EventStream.dirty`.
  --
  -- @function dirty
  -- @treturn bool whether processing is required

  __inherited: (cls) => cls.__base.__tostring = @__tostring

{
  :IOStream
}
