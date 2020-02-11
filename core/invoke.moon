import Const from require 'core.const'
import Action from require 'core.base'
import Scope from require 'core.scope'

class UpdateChildren
  new: (@children) =>

  update: (dt) =>
    for child in *@children
      -- L\trace "updating #{child}"
      L\push child\update, dt

  get: => @children[#@children]\get!
  getc: => @children[#@children]\getc!

  __tostring: => '<forwarder>'

class op_invoke extends Action
  patch: (head) =>
    return true if head == @head

    @op\destroy! if @op

    @head = head
    assert @head.type == 'opdef', "cant op-invoke #{@head}"
    @op = @head\getc!!
  
    true
    
  eval: (scope, tail) =>
    L\trace "evaling #{@}"
    args = L\push -> [L\push expr\eval, scope, @registry for expr in *tail]

    -- Const 'op', with @op
    with @op
      \setup unpack args

class fn_invoke extends Action
  -- @TODO:
  -- need to :patch() the case where the new head is a new fndef
  -- but corresponds to the last head over time

  patch: (head) =>
    return true if head == @head

    @head = head

    true

  eval: (outer_scope, tail) =>
    assert @head.type == 'fndef', "cant fn-invoke #{@head}"
    { :params, :body, :scope } = @head\getc!

    assert #params == #tail, "argument count mismatch in #{@head}"

    fn_scope = Scope @, scope

    for i=1,#params
      name = params[i]\getc!
      argm = tail[i]
      fn_scope\set name, L\push argm\eval, outer_scope, @registry

    body = body\clone @tag

    body\eval fn_scope, @registry

class do_expr extends Action
  eval: (scope, tail) =>
    UpdateChildren [(expr\eval scope, @registry) or Const.empty! for expr in *tail]

{
  :op_invoke, :fn_invoke
  :UpdateChildren
}
