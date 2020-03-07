----
-- Persistent expression Operator.
--
-- @classmod Op
import Value from require 'core.value'

class Op
--- Op interface.
--
-- methods that have to be implemented by `Op` implementations.
-- @section interface

  --- construct a new instance.
  --
  -- The super-constructor can be used to construct a `Value` instance in `@out`.
  --
  -- @function new

  --- parse arguments and patch self.
  --
  -- Called once every eval-cycle. `inputs` is a list of `Result`s that are the
  -- argument to this op. The `inputs` have to be wrapped in `Input` instances
  -- to define update behaviour. Use `base.match` to parse them, then delegate to
  -- `super\setup` to patch the `Input` instances.
  --
  -- @function setup
  -- @tparam inputs [`Result`] a sequence of `Result`s
  -- @tparam scope Scope the active scope

  --- handle incoming events and update `@out` (optional).
  --
  -- Called once per frame if any `Input`s are dirty. Some `Input`s (like
  -- `ValueInput`) have special behaviour immediately after `\setup`, that can
  -- cause them to become dirty at eval-time. In this case, an eval-time tick
  -- is executed. You can detect this using the `setup` parameter.
  --
  -- `\tick` is called after `\setup`. `tick` is not called immediately after
  -- `\setup` if no `@inputs` are dirty. Update `@out` here.
  --
  -- @tparam bool setup whether this is an eval-time tick
  tick: =>

  --- called when the Op is destroyed (optional).
  destroy: =>

  --- a `Value` instance representing this Op's computed output value.
  --
  -- Must be set to a `Value` instance once `\setup` finishes. Must not change
  -- type, be removed or replaced outside of `\new` and `\setup`. Should have a
  -- value assigned via `\set` or the `Value` constructor once `\tick` is
  -- called the first time. If `@out`'s value is not initialized in `\new`
  -- or `\setup`, the implementation must make sure `\tick(true)` is called at
  -- least on the first eval-cycle the Op goes through, e.g. by using a
  -- `ValueInput`.
  --
  -- @tfield Value out

--- implementation utilities.
--
-- super-methods and utilities for use by implementations.
-- @section super

  --- if `type` is passed, an output stream is instantiated.
  -- if `init` is passed, the stream is initialized to that Lua value.
  -- it is okay not to use this and create the output stream in :setup() if the
  -- type is not known at this time.
  --
  -- @tparam[opt] string type the type-name for `@out`
  -- @tparam[optchain] any init the initial value for `@out`
  new: (type, init) =>
    if type
      @out = Value type, init

  --- setup previous `@inputs`, if any, with the new inputs, and write them to
  -- `@inputs`. The `inputs` table can be nested with string or integer keys,
  -- but all leaf-entries must be `Input` instances. It must not contain loops
  -- or instances of other classes.
  --
  -- @tparam table inputs table of `Input`s
  setup: do
    do_setup = (old, cur) ->
      for k, cur_val in pairs cur
        old_val = old and old[k]

        -- are these inputs or nested tables?
        cur_plain = cur_val and not cur_val.__class
        old_plain = old_val and not old_val.__class

        if cur_plain and old_plain
          -- both are tables, recurse
          do_setup old_val, cur_val
        elseif not (cur_plain or old_plain)
          -- both are streams (or nil), setup them
          cur_val\setup old_val

    (inputs) =>
      old_inputs = @inputs
      @inputs = inputs
      do_setup old_inputs, @inputs

  --- yield all `Input`s from the (potentially nested) inputs table
  --
  -- @treturn iterator iterator over all `Input`s
  all_inputs: do
    do_yield = (table) ->
      for k, v in pairs table
        if v.__class
          coroutine.yield v
        else
          do_yield v

    => coroutine.wrap -> do_yield @inputs

  --- `\unwrap` all `Input`s in `@inputs` and return a table with the same
  -- shape.
  --
  -- @treturn table the values of all `Input`s
  unwrap_all: do
    do_unwrap = (value) ->
      if value.__class
        value\unwrap!
      else
        {k, do_unwrap v for k,v in pairs value}

    => do_unwrap @inputs

  __tostring: => "<op: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

{
  :Op
}
