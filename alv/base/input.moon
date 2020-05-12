----
-- Update scheduling policy for `Op` arguments.
--
-- @classmod Input
import Constant, SigStream, EvtStream, IOStream from require 'alv.result'
import RTNode from require 'alv.rtnode'

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
  -- @tparam Result result
  new: (@result) =>
    assert @result, "nil passed to Input: #{value}"

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
  -- `result`:@{SigStream:dirty|dirty}.
  --
  -- @treturn bool whether processing is necessary
  dirty: => @result\dirty!

  --- leave setup state (optional).
  --
  -- called after the `Op` has completed (or skipped) its first `Op:tick` after
  -- `Op:setup`. Must prepare this instance for dataflow operation.
  finish_setup: =>

  --- unwrap to Lua value (optional).
  --
  -- @treturn any the raw Lua value
  unwrap: => @result\unwrap!

  --- return the type name of this `Input` (optional).
  type: => @result.type

  --- return the metatype name of this `Input` (optional).
  metatype: => @result.metatype

  --- the current value
  -- @tfield Result result

  --- the Input mode
  -- @tfield string mode `'hot'`, `'cold'` or `'io'`.
  mode: 'hot'

--- members
-- @section members

  --- alias for `unwrap`.
  __call: => @result\unwrap!

  __tostring: => "#{@@__name}:#{@result}"
  __inherited: (cls) =>
    cls.__base.__call = @__call
    cls.__base.__tostring = @__tostring

--- static functions
-- @section static

  --- Create a `cold` `Input`.
  --
  -- Never marked dirty. Use this for input results that are only read when
  -- another `Input` is dirty.
  --
  -- @tparam Result|RTNode value
  @cold: (value) ->
    if value.__class == RTNode
      value = assert value.result, "Input from node without result!"
    ColdInput value

  --- Create a `hot` `Input`.
  --
  -- Behaviour depends on what kind of `Result` `value` is:
  --
  -- - `Constant`: treated like `cold`.
  -- - `SigStream`: Marked dirty only if old and new `SigStream` differ.
  -- - `EvtStream` and `IOStream`: Marked dirty only if the current
  --   `EvtStream` is dirty.
  --
  -- This is the most common `Input` strategy.
  --
  -- @tparam Result|RTNode value
  @hot: (value) ->
    if value.__class == RTNode
      value = assert value.result, "Input from node without result!"

    InputType = match_parent value, mapping
    assert InputType, "Input from unknown value: #{value}"
    InputType value

class ColdInput extends Input
  mode: 'cold'
  dirty: => false

class ValueInput extends Input
  new: (result) =>
    super result
    @mode = if @result.metatype == '=' then 'cold' else 'hot'

  setup: (old) =>
    @dirty_setup = not old or @result != old.result

  finish_setup: => @dirty_setup = nil

  dirty: =>
    return @dirty_setup if @dirty_setup != nil
    @result\dirty!

class IOInput extends Input
  mode: 'io'

mapping = {
  [Constant]: ValueInput
  [SigStream]: ValueInput
  [EvtStream]: Input
  [IOStream]: IOInput
}

{
  :Input
}
