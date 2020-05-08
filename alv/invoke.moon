----
-- Builtins for invoking `Op`s and `FnDef`s.
--
-- @module invoke
import RTNode from require 'alv.rtnode'
import Builtin from require 'alv.base'
import Scope from require 'alv.scope'
import Error from require 'alv.error'
import Primitive from require 'alv.types'

opdef = Primitive 'opdef'
fndef = Primitive 'fndef'
sym = Primitive 'sym'

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

--- `Builtin` implementation that invokes an `Op`.
--
-- @type op_invoke
class op_invoke extends Builtin
  --- `Builtin:setup` implementation.
  --
  -- `Op:fork`s the `prev`'s `Op` instance if given. Creates a new instance
  -- otherwise.
  setup: (prev) =>
    if prev
      @op = prev.op\fork!
      prev.forked = COPILOT.T
    else
      def = @head\unwrap opdef, "cant op-invoke #{@head}"
      @op = def!

  --- `Builtin:destroy` implementation.
  --
  -- calls `op`:@{Op:destroy|destroy}.
  destroy: =>
    if @forked ~= COPILOT.T
      @op\destroy!

  --- perform an `Op` invocation.
  --
  -- `AST:eval`s the tail, and passes the result to `op`:@{Op:setup|setup}. Then
  -- checks if any of `op`:@{Op:all_inputs|all_inputs} are @{Input:dirty|dirty},
  -- and if so, calls `op`:@{Op:tick|tick}.
  --
  -- The `RTNode` contains `op`, `Op.value` and all the `RTNode`s from the tail.
  --
  -- @tparam Scope scope the active scope
  -- @tparam {AST,...} tail the arguments to this expression
  -- @treturn RTNode
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

    RTNode :children, value: @op.out, op: @op

  --- The `Op` instance.
  --
  -- @tfield Op op

--- `Builtin` implementation that invokes a `FnDef`.
--
-- @type fn_invoke
class fn_invoke extends Builtin
  --- evaluate a user-function invocation.
  --
  -- Creates a new `Scope` that inherits from `FnDef.scope` and has
  -- `caller_scope` as an additional parent for dynamic symbol resolution.
  -- Then `AST:eval`s the tail in `caller_scope`, and defines the results to the
  -- names in `FnDef.params` in the newly created scope. Lastly, `AST:clone`s
  -- `FnDef.body` with the prefix `Builtin.tag`, and `AST:eval`s it in the newly
  -- created `Scope`.
  --
  -- The `RTNode` contains the `Stream` from the cloned AST, and its children
  -- are all the `RTNode`s from evaluating the tail as well as the cloned
  -- `AST`s.
  --
  -- @tparam Scope caller_scope the active scope
  -- @tparam {AST,...} tail the arguments to this expression
  -- @treturn RTNode the result of this evaluation
  eval: (caller_scope, tail) =>
    name = get_name @head, @cell\head!
    frame = "invoking function #{name} at [#{@tag}]"

    fndef = @head\unwrap fndef, "cant fn-invoke #{@head}"
    { :params, :body } = fndef
    if #params != #tail
      err = Error 'argument', "expected #{#params} arguments, found #{#tail}"
      err\add_frame frame
      error err

    fn_scope = Scope fndef.scope, caller_scope

    children = for i=1,#params
      name = params[i]\unwrap sym
      with L\push tail[i]\eval, caller_scope
        fn_scope\set name, \make_ref!

    clone = body\clone @tag
    result = Error.wrap frame, clone\eval, fn_scope

    table.insert children, result
    RTNode :children, value: result.value

{
  :op_invoke, :fn_invoke
}
