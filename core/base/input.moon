----
-- Update scheduling policy for `Op` arguments.
--
-- @classmod Input
import ValueStream, EventStream, IOStream from require 'core.stream'
import Result from require 'core.result'

inherits = (klass, frm) ->
  assert klass, "cant find the ancestor of nil"
  return true if klass == frm
  while klass.__parent
    return true if klass.__parent == frm
    klass = klass.__parent
  false

match_parent = (inst, map) ->
  klass = assert inst and inst.__class, "not an instance"
  if key = map[klass]
    return key

  while klass.__parent
    if key = map[klass.__parent]
      return key

    klass = klass.__parent

local ColdInput, ValueInput, IOInput, mapping

class Input
--- Input interface.
--
-- Methods that have to be implemented by `Input` implementations.
-- @section interface

  --- create a new Input.
  --
  -- @classmethod
  -- @tparam Stream stream
  new: (@stream) =>
    assert @stream, "nil passed to Input: #{value}"

  --- copy state from old instance (optional).
  --
  -- called by `Op:setup` with another `Input` instance or `nil` once this instance is
  -- registered. Must prepare this instance for `dirty`.
  --
  -- May enter a 'setup state' that is exited using `finish_setup`.
  --
  -- @tparam ?Input prev previous `Input` intance or nil
  setup: (prev) =>

  --- whether this input requires processing (optional).
  --
  -- must return a boolean indicating whether `Op`s that refer to this instance
  -- should be notified (via `Op:tick`). If not overwritten, delegates to
  -- `stream`:@{ValueStream:dirty|dirty}.
  --
  -- @treturn bool whether processing is necessary
  dirty: => @stream\dirty!

  --- leave setup state (optional).
  --
  -- called after the `Op` has completed (or skipped) its first `Op:tick` after
  -- `Op:setup`. Must prepare this instance for dataflow operation.
  finish_setup: =>

  --- unwrap to Lua value (optional).
  --
  -- @treturn any the raw Lua value
  unwrap: => @stream\unwrap!

  --- return the type name of this `Input` (optional).
  type: => @stream.type

  --- the current value
  --
  -- @tfield ValueStream stream

--- members
-- @section members

  --- alias for `unwrap`.
  __call: => @stream\unwrap!

  __tostring: => "#{@@__name}:#{@stream}"
  __inherited: (cls) =>
    cls.__base.__call = @__call
    cls.__base.__tostring = @__tostring

--- static functions
-- @section static

  --- Create a `cold` `Input`.
  --
  -- Never marked dirty. Use this for input streams that are only read when
  -- another `Input` is dirty.
  --
  -- @tparam Stream|Result value
  @cold: (value) ->
    if value.__class == Result
      value = assert value.value, "Input from result without value!"
    ColdInput value

  --- Create a `hot` `Input`.
  --
  -- Behaviour depends on what kind of `Stream` `value` is:
  --
  -- - `ValueStream`: Marked dirty for the eval-tick if old and new `ValueStream` differ.
  -- - `EventStream` and `IOStream`: Marked dirty only if the current `EventStream` is dirty.
  --
  -- This is the most common `Input` strategy.
  --
  -- @tparam Stream|Result value
  @hot: (value) ->
    if value.__class == Result
      value = assert value.value, "Input from result without value!"

    InputType = match_parent value, mapping
    assert InputType, "Input from unknown value: #{value}"
    InputType value

class ColdInput extends Input
  dirty: => false

class ValueInput extends Input
  setup: (old) => @dirty_setup = not old or @stream != old.stream
  finish_setup: => @dirty_setup = nil
  dirty: =>
    return @dirty_setup if @dirty_setup != nil
    @stream\dirty!

class IOInput extends Input
  io: true

mapping = {
  [ValueStream]: ValueInput
  [EventStream]: Input
  [IOStream]: IOInput
}

{
  :Input
}
