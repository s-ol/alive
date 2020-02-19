-- base definitions for extensions
import Value from require 'core.value'

unpack or= table.unpack

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
  setup: (@inputs) =>

  -- called once per frame if any inputs or impulses are dirty, and once
  -- immediately after :setup(). 'first' will be true in the latter case.
  -- Should update @out.
  tick: (first) =>

  -- called once when the Op is destroyed
  destroy: =>

-- utilities
  unwrap_inputs: =>
    unpack [input! for input in *@inputs]

  assert_types: (...) =>
    num = select '#', ...
    assert #@inputs >= num, "argument count mismatch"
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
  :Dispatcher
  :Op
  :Action
  :FnDef
}
