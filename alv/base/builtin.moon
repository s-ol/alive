----
-- Builtin / Special Form evaluation Strategy (`builtin`).
--
-- Responsible for quoting/evaluating subexpressions, instantiating and setting
-- up `Op`s, updating the current `Scope`, etc.
-- See `builtin` and `invoke` for examples.
--
-- @classmod Builtin

class Builtin
--- Builtin interface.
--
-- methods that have to be implemented by `Builtin` implementations.
-- @section interface

  --- create a new instance.
  --
  -- @tparam Cell cell the Cell to evaluate
  -- @tparam Value head the (`AST:eval`d) `head` of the Cell to evaluate
  new: (@cell, @head) =>
    @tag = @cell.tag
    @tag\register @

  --- perform the actual evaluation.
  --
  -- Implementations should:
  --
  -- - eval or quote `tail` values
  -- - perform scope effects
  -- - wrap all child-results
  --
  -- @function eval
  -- @tparam Scope scope the active scope
  -- @tparam {AST,...} tail the arguments to this expression
  -- @treturn RTNode the result of this evaluation

  --- store the evaluation result for access by editor and return it.
  --
  -- This should always be called via `super` as the last statement in all
  -- overriden `eval` methods.
  --
  -- @tparam RTNode node the evaluation result
  eval: (@node) => @node

  --- free resources
  destroy: =>

  --- setup or copy state from previous instance of same type.
  --
  -- `prev` is only passed if Builtin types of prev and current expression match.
  -- Otherwise, or when no previous expression exists, `nil` is passed.
  --
  -- @tparam ?Builtin prev the previous Builtin instance
  setup: (prev) =>

  --- collect visualisation data (optional).
  --
  -- This may return any simple Lua value, including Lua tables, as long as it
  -- has no metatables, multiple references/loops, userdata etc.
  --
  -- This value is exposed to alv editors in order to render realtime
  -- visualisations overlaid onto the program text.
  --
  -- @treturn table vis
  vis: => {}

  --- the `Cell` this Builtin was created for.
  -- @tfield Cell cell

  --- the evaluated head of `cell`.
  -- @tfield AST head

  --- the identity of `cell`.
  -- @tfield Tag tag

  --- the last result of `eval`.
  -- @tfield RTNode node

--- static functions
-- @section static

  --- create and setup a `Builtin` for a given tag, then evaluate it.
  --
  -- Create a new instance using `tag` and `head` and call `setup` on it.
  -- If a previous instance with the same `tag` exists and has the same `head`,
  -- it pass it to `setup`. Register the `Builtin` with `tag`, evaluate it
  -- and return the `RTNode`.
  --
  -- @tparam Cell cell the `Cell` being evaluated
  -- @tparam Scope scope the active scope
  -- @tparam Value head the (`AST:eval`d) head of the `Cell` being evaluated
  -- @treturn RTNode the result of evaluation
  @eval_cell: (cell, scope, head) =>
    last = cell.tag\last!
    compatible = last and (last.__class == @) and last.head == head

    L\trace if compatible
      "reusing #{last} for #{cell.tag} <#{@__name} #{head}>"
    else if last
      "replacing #{last} with new #{cell.tag} <#{@__name} #{head}>"
    else
      "initializing #{cell.tag} <#{@__name} #{head}>"

    builtin = @ cell, head
    if compatible
      builtin\setup last
    else
      builtin\setup nil

    builtin\eval scope, cell\tail!

  __tostring: => "<#{@@__name}[#{@tag}] #{@head}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

{
  :Builtin
}
