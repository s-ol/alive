-- base definitions for extensions
import Value from require 'core.value'
import Result from require 'core.result'
import match from require 'core.pattern'

unpack or= table.unpack

-- an incoming side-effect adapter, polled by the main event loop to pump
-- events into the dataflow graph.
--
-- subclasses must implement this interface:
--
-- :new() - construct a new instance
--
--   must prepare the instance for :dirty().
--
-- :tick() - poll for changes
--
--   called every frame by the event loop to update internal state.
--
-- :dirty() - whether this adapter requires processing
--
--   must return a boolean indicating whether `Op`s that refer to this instance
--   via `IOInput` should be notified (via `Op:tick()`). May be called multiple
--   multiple times. May be called before :tick() on the first frame after
--   construction.
--
class IO
  -- called in the main event loop
  tick: =>

  -- whether a tree update is necessary
  dirty: =>

-- a persistent expression Operator
--
-- subclasses must implement this interface:
--
-- :new() - construct a new instance
--
--   the super-constructor can be used to construct a `Value` instance in @out.
--
-- :setup(inputs, scope) - parse arguments and patch self
--
--   called once every eval-cycle. `inputs` is a list of `Result`s that are the
--   argument to this op. The `inputs` have to be wrapped in `Input` instances
--   to define update behaviour. Use `match` to parse them, then delegate to
--   super to patch the `Input` instances.
--
-- :tick(setup) - handle incoming events and update @out
--
--   called once per frame if any inputs are dirty. Some `Input`s (like
--   `ValueInput`) have special behaviour immediately after :setup(). You can
--   detect this using the `setup` parameter, which is true the first time
--   :tick() is called after :setup(). :tick() is not called immediately after
--   :setup() if no `@inputs` are dirty. Update @out here.
--
-- :destroy() - called when the Op is destroyed
--
-- .out - a `Value` instance representing this Op's computed output value.
--
--   @out must be set to a `Value` instance once :setup() finishes. @out must
--   not change type, be removed or replaced outside of :new() and :setup().
--   @out should have a value assigned via :set() or the `Value` constructor
--   once :tick(true) is called. If @out's value is not initialized in :new()
--   or :setup(), the implementation must make sure :tick(true) is called at
--   least on the first eval-cycle the Op goes through, e.g. by using a
--   `ValueInput`.
--
class Op
-- super-implementations for extensions
  -- if `type` is passed, an output stream is instantiated.
  -- if `init` is passed, the stream is initialized to that Lua value.
  -- it is okay not to use this and create the output stream in :setup() if the
  -- type is not known at this time.
  new: (type, init) =>
    if type
      @out = Value type, init

  -- setups previous @inputs, if any, with the new inputs, and writes them to
  -- `@inputs`. The `inputs` table can be nested with string or integer keys,
  -- but all leaf-entries must be `Input` instances. It must not contain loops
  -- or instances of other classes.
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

  tick: =>
  destroy: =>

-- utilities
  -- iterate over the (potentially nested) inputs table
  all_inputs: do
    do_yield = (table) ->
      for k, v in pairs table
        if v.__class
          coroutine.yield v
        else
          do_yield v

    => coroutine.wrap -> do_yield @inputs

  unwrap_all: do
    do_unwrap = (value) ->
      if value.__class
        value\unwrap!
      else
        {k, do_unwrap v for k,v in pairs value}

    => do_unwrap @inputs

  assert_types: (...) =>
    num = select '#', ...
    assert #@inputs >= num, "argument count mismatch"
    @assert_first_types ...

  assert_first_types: (...) =>
    num = select '#', ...
    for i = 1, num
      expect = select i, ...
      assert @inputs[i].type == expect, "expected argument #{i} of #{@} to be of type #{expect} but found #{@inputs[i]}"

-- static
  __tostring: => "<op: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

-- a builtin / special form / cell-evaluation strategy.
--
-- responsible for quoting/evaluating subexpressions, instantiating and patching
-- Ops updating the current Scope, etc. See core.builtin and core.invoke for
-- many examples.
class Action
  -- head: the (:eval'd) head of the Cell to evaluate (a Const)
  -- tag:  the Tag of the expression to evaluate
  new: (head, @tag) =>
    @patch head

  -- * eval args
  -- * perform scope effects
  -- * patch nested exprs
  -- * return runtime-tree value
  eval: (scope, tail) => error "not implemented"

  -- free resources
  destroy: =>

  -- update this instance for :eval() with new head
  -- if :patch() returns false, this instance is :destroy'ed and recreated
  -- instead must *not* return false when called after :new()
  -- only considered if Action types match
  patch: (head) =>
    if head == @head
      true

    @head = head

-- static
  -- find & patch the action for the expression with Tag 'tag' if it exists,
  -- and is compatible with the new Cell contents, otherwise instantiate it.
  -- register the action with the tag, evaluate it and return the Result
  @eval_cell: (scope, tag, head, tail) =>
    last = tag\last!
    compatible = last and
                 (last.__class == @) and
                 (last\patch head) and
                 last

    L\trace if compatible
      "reusing #{last} for #{tag} <#{@__name} #{head}>"
    else if last
      "replacing #{last} with new #{tag} <#{@__name} #{head}>"
    else
      "initializing #{tag} <#{@__name} #{head}>"

    action = if compatible
      tag\keep compatible
      compatible
    else
      last\destroy! if last
      with next = @ head, tag
        tag\replace next

    action\eval scope, tail

  __tostring: => "<#{@@__name} #{@head}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

-- an ALV function definition
--
-- when called, expands its body with params bound to the fn arguments
-- (see core.invoke.fn-invoke)
class FnDef
  -- params: sequence of (:quote'd) symbols, each naming a function parameter
  -- body:   (:quote'd) expression the function evaluates to
  -- scope:  the lexical scope the function was defined in (closure)
  new: (@params, @body, @scope) =>

  __tostring: =>
    "(fn (#{table.concat [p\stringify! for p in *@params], ' '}) ...)"

-- an update scheduling policy for `Op`.
--
-- subclasses must implement this interface:
--
-- :new(value) - create an instance
--
--   `value` is either a `Value` or a `Result` instance and should be unwrapped.
--
-- :setup(prev) - copy state from old instance
--
--    called by `Op:setup()` with another `Input` instance or `nil` once this instance is
--    registered. Must prepare this instance for :dirty().
--
--- :dirty() - whether this input requires processing
--
--   must return a boolean indicating whether `Op`s that refer to this instance
--   should be notified (via `Op:tick()`).
--
-- :finish_setup() - leave setup state
--
--   called after the Op has completed (or skipped) its first `Op:tick()` after
--   `Op:setup()`. Must prepare this instance for dataflow operation.
--
class Input
  new: (value) =>
    assert value, "nil passed to Input: #{value}"
    @stream = switch value.__class
      when Result
        assert value.value, "Input from result without value!"
      when Value
        value
      else
        error "Input from unknown value: #{value}"

  setup: (previous) =>

  finish_setup: =>
  dirty: => @stream\dirty!
  unwrap: => @stream\unwrap!
  type: => @stream.type

  __call: => @stream\unwrap!
  __tostring: => "#{@@__name}:#{@stream}"
  __inherited: (cls) =>
    cls.__base.__call = @__call
    cls.__base.__tostring = @__tostring

-- Never marked dirty. Use this for input streams that are only read when
-- another input fires.
class ColdInput extends Input
  dirty: => false

-- Marked dirty for the setup-tick if old and new stream differ in current
-- value. This is the most common `Input` strategy. Should be used whenever a
-- value denotes state.
class ValueInput extends Input
  setup: (old) => @dirty_setup = not old or @stream != old.stream
  finish_setup: => @dirty_setup = false
  dirty: => @dirty_setup or @stream\dirty!

-- Only marked dirty if the input stream itself is dirty. Should be used
-- whenever a value denotes a momentary event or impulse.
class EventInput extends Input

-- Marked dirty when an IO object is dirty. Must be used for IO values.
class IOInput extends Input
  impure: true
  dirty: => @stream\unwrap!\dirty!

{
  :IO
  :Op
  :Action
  :FnDef

  :ValueInput, :EventInput, :IOInput, :ColdInput

  -- redundant exports, to keep anything an extension might need in one import
  :Value, :Result
  :match
}
