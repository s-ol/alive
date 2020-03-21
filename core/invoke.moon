----
-- Builtins for invoking `Op`s and `FnDef`s.
--
-- @module invoke
import Value from require 'core.value'
import Result from require 'core.result'
import Action from require 'core.base'
import Scope from require 'core.scope'
import Error from require 'core.error'

get_name = (value, raw) ->
  meta = if value.meta then value.meta.name
  locl = if raw and raw.type == 'sym' then raw!

  if locl
    if meta and meta != locl
      "'#{meta}' (local '#{locl}')"
    else
      "'#{locl}'"
  else if meta
    "'#{meta}'"
  else
    "(unnamed)"

--- `Action` implementation that invokes an `Op`.
--
-- @type op_invoke
class op_invoke extends Action
  --- `Action:setup` implementation.
  --
  -- `Op:fork`s the `prev`'s `Op` instance if given. Creates a new instance
  -- otherwise.
  setup: (prev) =>
    if prev
      @op = prev.op\fork!
    else
      def = @head\unwrap 'opdef', "cant op-invoke #{@head}"
      @op = def!

  --- `Action:destroy` implementation.
  --
  -- calls `op`:@{Op:destroy|destroy}.
  destroy: => @op\destroy!

  --- evaluate an `Op` invocation.
  --
  -- `AST:eval`s the tail, and passes the result to `op`:@{Op:setup|setup}. Then
  -- checks if any of `op`:@{Op:all_inputs|all_inputs} are @{Input:dirty|dirty},
  -- and if so, calls `op`:@{Op:tick|tick}.
  --
  -- The `Result` contains `op`, `Op.value` and all the `Result`s from the tail.
  --
  -- @tparam Scope scope the active scope
  -- @tparam {AST,...} tail the arguments to this expression
  -- @treturn Result
  eval: (scope, tail) =>
    children = [L\push expr\eval, scope for expr in *tail]

    frame = "invoking op #{get_name @head, @cell\head!} at [#{@tag}]"
    Error.wrap frame, @op\setup, [result for result in *children], scope

    any_dirty = false
    for input in @op\all_inputs!
      if input\dirty!
        any_dirty = true
        break

    if any_dirty
      @op\tick true

    for input in @op\all_inputs!
      input\finish_setup!

    Result :children, value: @op.out, op: @op

  --- The `Op` instance.
  --
  -- @tfield Op op

--- `Action` implementation that invokes a `FnDef`.
--
-- @type fn_invoke
class fn_invoke extends Action
  --- evaluate a user-function invocation.
  --
  -- Creates a new `Scope` that inherits from `FnDef.scope` and has
  -- `outer_scope` as an additional parent for dynamic symbol resolution.
  -- Then `AST:eval`s the tail in `outer_scope`, and defines the results to the
  -- names in `FnDef.params` in the newly created scope. Lastly, `AST:clone`s
  -- `FnDef.body` with the prefix `Action.tag`, and `AST:eval`s it in the newly
  -- created `Scope`.
  --
  -- The `Result` contains the `Value` from the cloned AST, and its children are
  -- all the `Result`s from evaluating the tail as well as the cloned `AST`s.
  --
  -- @tparam Scope outer_scope the active scope
  -- @tparam {AST,...} tail the arguments to this expression
  -- @treturn Result the result of this evaluation
  eval: (outer_scope, tail) =>
    name = get_name @head, @cell\head!
    frame = "invoking function #{name} at [#{@tag}]"

    { :params, :body, :scope } = @head\unwrap 'fndef', "cant fn-invoke #{@head}"
    if #params != #tail
      error with Error 'argument', "expected #{#params} arguments, found #{#tail}"
        \add_frame frame

    fn_scope = Scope scope, outer_scope

    children = for i=1,#params
      name = params[i]\unwrap 'sym'
      with L\push tail[i]\eval, outer_scope
        fn_scope\set name, \make_ref!

    clone = body\clone @tag
    result = Error.wrap frame, clone\eval, fn_scope

    table.insert children, result
    Result :children, value: result.value

{
  :op_invoke, :fn_invoke
}
