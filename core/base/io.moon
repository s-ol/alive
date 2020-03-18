----
-- Incoming side-effect adapter, creating events for the dataflow graph.
--
-- Polled by the main event loop to kick of events that cause the the dataflow
-- graph to ripple results.
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

  __tostring: => "<IO #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

{
  :IO
}
