----
-- Incoming side-effect adapter, polled by the main event loop to pump
-- events into the dataflow graph.
--
-- @classmod IO

class IO
--- IO interface.
--
-- methods that have to be implemented by `IO` implementations.
-- @section interface

  --- construct a new instance.
  --
  -- Must prepare the instance for `dirty` to be called.
  -- @classmethod
  new: =>

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
  -- @treturn bool whether processing is required
  dirty: =>

{
  :IO
}
