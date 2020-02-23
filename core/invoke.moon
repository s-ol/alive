import Result, Value from require 'core.value'
import Action from require 'core.base'
import Scope from require 'core.scope'

class op_invoke extends Action
  patch: (head) =>
    return true if head == @head

    @op\destroy! if @op

    def = head\unwrap 'opdef', "cant op-invoke #{@head}"
    @head, @op = head, def!
    @first = true

    true
    
  eval: (scope, tail) =>
    children = L\push -> [L\push expr\eval, scope for expr in *tail]
    @op\setup [child.value for child in *children]
    @op\tick @first
    @first = nil

    Result :children, value: @op.out, op: @op

class fn_invoke extends Action
  -- @TODO:
  -- need to :patch() the case where the new head is a new fndef
  -- but corresponds to the last head over time

  patch: (head) =>
    return true if head == @head

    @head = head

    true

  eval: (outer_scope, tail) =>
    { :params, :body, :scope } = @head\unwrap 'fndef', "cant fn-invoke #{@head}"

    assert #params == #tail, "argument count mismatch in #{@head}"

    fn_scope = Scope @, scope

    children = for i=1,#params
      name = params[i]\unwrap 'sym'
      with L\push tail[i]\eval, outer_scope
        fn_scope\set name, .value

    body = body\clone @tag
    result = body\eval fn_scope

    table.insert children, result
    Result :children, value: result.value

{
  :op_invoke, :fn_invoke
}
