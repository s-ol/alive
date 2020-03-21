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
  -- @tparam Cell cell the Cell to evaluate
  -- @tparam Value head the (`AST:eval`d) `head` of the Cell to evaluate
  new: (@cell, @head) =>
    @tag = @cell.tag
    @tag\replace @

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

  --- the `Cell` this Action was created for.
  -- @tfield Cell cell

  --- the evaluated head of `cell`.
  -- @tfield AST head

  --- the identity of `cell`.
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
  -- @tparam Cell cell the `Cell` being evaluated
  -- @tparam Scope scope the active scope
  -- @tparam Value head the (`AST:eval`d) head of the `Cell` being evaluated
  -- @treturn Result the result of evaluation
  @eval_cell: (cell, scope, head) =>
    last = cell.tag\last!
    compatible = last and (last.__class == @) and last.head == head

    L\trace if compatible
      "reusing #{last} for #{cell.tag} <#{@__name} #{head}>"
    else if last
      "replacing #{last} with new #{cell.tag} <#{@__name} #{head}>"
    else
      "initializing #{cell.tag} <#{@__name} #{head}>"

    action = @ cell, head
    if compatible
      action\setup last
    else
      last\destroy! if last
      action\setup nil

    action\eval scope, cell\tail!

  __tostring: => "<#{@@__name} #{@head}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

{
  :Action
}
