----
-- Builtin / Special Form / `Cell`-evaluation Strategy.
--
-- Responsible for quoting/evaluating subexpressions, instantiating and patching
-- `Op`s, updating the current `Scope`, etc.
-- See `builtin` and `invoke` for examples.
--
-- @classmod Action

class Action
--- Action interface.
--
-- methods that have to be implemented by `Action` implementations.
-- @section interface

  --- create a new instance
  -- @tparam Value head the (`\eval`d) head of the Cell to evaluate
  -- @tparam Tag tag the Tag of the expression to evaluate
  new: (head, @tag) =>
    @patch head

  --- perform the actual evaluation
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

  --- attempt to update this instance with a new `@head` prior to `\eval`.
  --
  -- If `\patch` returns `false`, this instance is `\destroy`ed and recreated.
  -- Must *not* return `false` when called immediately after `\new`.
  -- Only considered if Action types of old and new expression match.
  --
  -- @tparam AST head the new head value
  -- @treturn bool whether patching was successful
  patch: (head) =>
    if head == @head
      true

    @head = head

--- static functions
-- @section static

  --- get-or-update an `Action` for a given tag, then evaluate it.
  --
  -- Find the action for the expression with `Tag` `tag` if it exists,
  -- and is compatible with the new `head`, otherwise instantiate one.
  -- Register the `Action` with `tag`, evaluate it and return the `Result`.
  --
  -- @tparam Scope scope the active scope
  -- @tparam Tag tag the tag of the `Cell` being evaluated
  -- @tparam Value head the (`\eval`d) head of the `Cell` being evaluated
  -- @tparam {Ast,...} tail the raw AST parameters to the `Cell` being evaluated
  -- @treturn Result the result of evaluation
  eval_cell: (scope, tag, head, tail) =>
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

{
  :Action
}
