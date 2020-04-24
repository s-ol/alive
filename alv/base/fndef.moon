----
-- user-function definition (`fndef`).
--
-- When called, expands to its body with params bound to the fn arguments (see
-- `invoke.fn_invoke`).
--
-- @classmod FnDef

class FnDef
--- static functions
-- @section static

  --- create a new instance
  --
  -- @classmethod
  -- @tparam {Value,...} params (unevaluated) naming the function parameters
  -- @tparam AST body (unevaluated) expression the function evaluates to
  -- @tparam Scope scope the lexical scope the function was defined in (closure)
  new: (@params, @body, @scope) =>

  __tostring: =>
    "(fn (#{table.concat [p\stringify! for p in *@params], ' '}) ...)"

{
  :FnDef
}
