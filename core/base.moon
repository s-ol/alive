-- base definitions for extensions
import Value, Result from require 'core.value'

unpack or= table.unpack

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

  merge: (previous) =>

  finish_setup: =>
  dirty: => @stream\dirty!
  unwrap: => @stream\unwrap!
  type: => @stream.type

  __call: => @stream\unwrap!
  __tostring: => "#{@@__name}:#{@stream}"
  __inherited: (cls) =>
    cls.__base.__call = @__call
    cls.__base.__tostring = @__tostring

-- ValueInput scheduling policy
--
-- during setup, only marked dirty if old and new stream differ in value
class ValueInput extends Input
  merge: (old) => @dirty_setup = not old or @stream\unwrap! != old\unwrap!
  finish_setup: => @dirty_setup = false
  dirty: => @dirty_setup or @stream\dirty!

-- EventInput scheduling policy
--
-- only marked dirty if the input stream itself is dirty
class EventInput extends Input

-- IOInput scheduling policy
--
-- lifts streams of IO objects to events
class IOInput extends Input
  dirty: => @stream\unwrap!\dirty!

class IO
  -- called in the main event loop
  tick: =>

  -- whether a tree update is necessary
  dirty: =>

-- a persistent expression Operator
--
-- accepts Const or Stream inputs and produces a Stream output
class Op
  new: (type, init) =>
    @impulses = {}

    if type
      @out = Value type, init

  -- (re)-initialize this Op with the given inputs
  -- after this method finishes, :tick(true) is called once, after which
  -- @impulses and @out have to be set and may not change until :setup()
  -- is called again.
  setup: do
    do_merge = (old, cur) ->
      for k, cur_val in pairs cur
        old_val = old and old[k]

        -- are these inputs or nested tables?
        cur_plain = cur_val and not cur_val.__class
        old_plain = old_val and not old_val.__class

        if cur_plain and old_plain
          -- both are tables, recurse
          do_merge old_val, cur_val
        elseif not (cur_plain or old_plain)
          -- both are streams (or nil), merge them
          cur_val\merge old_val

    (inputs) =>
      old_inputs = @inputs
      @inputs = inputs
      do_merge old_inputs, @inputs

  -- iterate over the (potentially nested) inputs table
  all_inputs: do
    do_yield = (table) ->
      for k, v in pairs table
        if v.__class
          coroutine.yield v
        else
          do_yield v

    => coroutine.wrap -> do_yield @inputs

  -- called once per frame if any inputs or impulses are dirty, and once
  -- immediately after :setup(). 'first' will be true in the latter case.
  -- Should update @out.
  tick: (first) =>

  -- called once when the Op is destroyed
  destroy: =>

-- utilities
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

-- a builtin / special form / cell-evaluation strategy
--
-- responsible for quoting/evaluating subexpressions,
-- instantiating and patching Ops,
-- updating the current Scope,
-- etc.
class Action
  -- head: the (:eval'd) head of the Cell to evaluate (a Const)
  -- tag:  the Tag of the expression to evaluate
  new: (head, @tag) =>
    @patch head

-- AST interface
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

-- a ALV function definition
--
-- when called, expands its body with params bound to the fn arguments
-- (see core.invoke.fn-invoke)
class FnDef
  -- params: sequence of (:quote'd) symbols, each naming a function parameter
  -- body:   (:quote'd) expression the function evaluates to
  -- scoe:   the lexical scope the function was defined in (closure)
  new: (@params, @body, @scope) =>

  __tostring: =>
    "(fn (#{table.concat [p\stringify! for p in *@params], ' '}) ...)"

{
  :ValueInput, :EventInput, :IOInput
  :Dispatcher
  :IO
  :Op
  :Action
  :FnDef
}
