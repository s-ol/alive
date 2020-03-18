----
-- Builtin / Special Form evaluation Strategy (`builtin`).
--
-- Responsible for quoting/evaluating subexpressions, instantiating and setting
-- up `Op`s, updating the current `Scope`, etc.
-- See `builtin` and `invoke` for examples.
--
-- @classmod Action

class Action
--- Action interface.
--
-- methods that have to be implemented by `Action` implementations.
-- @section interface

  --- create a new instance.
  --
  -- @tparam Value head the (`AST:eval`d) `head` of the Cell to evaluate
  -- @tparam Tag tag the Tag of the expression to evaluate
  new: (@head, @tag) =>

  --- perform the actual evaluation.
  --
  -- Implementations should:
  --
  -- - eval or quote `tail` values
  -- - perform scope effects
  -- - wrap all child-results
  --
  -- @tparam Scope scope the active scope
  -- @tparam {AST,...} tail the arguments to this expression
  -- @treturn Result the result of this evaluation
  eval: (scope, tail) => error "not implemented"

  --- free resources
  destroy: =>

  --- setup or copy state from previous instance of same type.
  --
  -- `prev` is only passed if Action types of prev and current expression match.
  -- Otherwise, or when no previous expression exists, `nil` is passed.
  --
  -- @tparam ?Action prev the previous Action instance
  setup: (prev) =>

  --- the head of the `Cell` this Action was created for.
  --
  -- @tfield AST head

  --- the identity of the `Cell` this Action was created for.
  --
  -- @tfield Tag tag

--- static functions
-- @section static

  --- create and setup an `Action` for a given tag, then evaluate it.
  --
  -- Create a new instance using `tag` and `head` and call `setup` on it.
  -- If a previous instance with the same `tag` exists and has the same `head`,
  -- it pass it to `setup`. Register the `Action` with `tag`, evaluate it
  -- and return the `Result`.
  --
  -- @tparam Scope scope the active scope
  -- @tparam Tag tag the tag of the `Cell` being evaluated
  -- @tparam Value head the (`AST:eval`d) head of the `Cell` being evaluated
  -- @tparam {AST,...} tail the raw AST parameters to the `Cell` being evaluated
  -- @treturn Result the result of evaluation
  @eval_cell: (scope, tag, head, tail) =>
    last = tag\last!
    compatible = last and (last.__class == @) and last.head == head

    L\trace if compatible
      "reusing #{last} for #{tag} <#{@__name} #{head}>"
    else if last
      "replacing #{last} with new #{tag} <#{@__name} #{head}>"
    else
      "initializing #{tag} <#{@__name} #{head}>"

    action = @ head, tag
    if compatible
      action\setup last
    else
      last\destroy! if last
      action\setup nil

    tag\replace action
    action\eval scope, tail

  __tostring: => "<#{@@__name} #{@head}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

{
  :Action
}
