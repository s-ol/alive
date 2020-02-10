import Const, Cell, Action, Scope from require 'core'

class UpdateChildren
  new: (@children) =>

  update: (dt) =>
    for child in *@children
      L\trace "updating #{child}"
      L\push child\update, dt

  get: => @children[#@children]\get!
  getc: => @children[#@children]\getc!

  __tostring: => '<forwarder>'

-- (def sym1 val-expr1
--     [sym2 val-expr2]...)
--
-- declare symbols in parent scope
--
-- if val-expr is a expand-time constant, defines a `Const`,
-- otherwise places a `Forward` for the expr
class def extends Action
  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail > 1, "'def' requires at least 2 arguments"
    assert #tail % 2 == 0, "'def' requires an even number of arguments"

    values = L\push ->
      return for i=1,#tail,2
        name, val_expr = tail[i], tail[i+1]
        name = (name\quote scope, @registry)\getc 'sym'

        val = val_expr\eval scope, @registry
        scope\set name, val
        val

    UpdateChildren values

-- (require name-str)
--
-- require a lua module and return its `Scope`
-- name-str has to be an expand-time constant
class require_mod extends Action
  eval: (scope,  tail) =>
    L\trace "expanding #{@}"
    assert #tail == 1, "'require' takes only one parameter"

    name = L\push tail[1]\eval, scope, @registry

    L\trace @, "loading module #{name}"
    scope = Scope.from_table require "lib.#{name\getc 'str'}"
    Const 'scope', scope

-- (use scope1 [scope2]...)
--
-- merge scopes into parent scope
-- scopes have to be expand-time constants
class use extends Action
  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    for child in *tail
      value = L\push child\eval, scope, @registry
      L\trace @, "merging #{value} into #{scope}"
      assert value.type == 'scope', "'use' only works on scopes"
      scope\use value\getc 'scope'

    nil

-- (fn (p1 [p2]...) body-expr)
--
-- declare a function
class fn extends Action
  class FnDef
    new: (@params, @body) =>

    __tostring: =>
      table.concat [p\stringify! for p in *@params], ' '

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail == 2, "'fn' takes exactly two arguments"
    { params, body } = tail


    assert params.__class == Cell, "'fn's first argument has to be an expression"
    param_symbols = for param in *params.children
      assert param.type == 'sym', "function parameter declaration has to be a symbol"
      param\quote scope, @registry

    body = body\quote scope, @registry
    Const 'fndef', FnDef param_symbols, body

class op_invoke extends Action
  patch: (head) =>
    return true if head == @head

    @op\destroy! if @op

    @head = head
    assert @head.type == 'opdef', "cant op-invoke #{@head}"
    @op = @head\getc!!
  
    true
    
  eval: (scope, tail) =>
    args = [expr\eval scope, @registry for expr in *tail]
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

  eval: (scope, tail) =>
    assert @head.type == 'fndef', "cant fn-invoke #{@head}"
    { :params, :body } = @head\getc!

    assert #params == #tail, "argument count mismatch in #{@head}"

    fn_scope = Scope @, scope

    for i=1,#params
      name = params[i]\getc!
      argm = tail[i]
      fn_scope\set name, L\push argm\eval, scope, @registry

    body\eval fn_scope, @registry

class do_expr extends Action
  class DoWrapper
    new: (@children) =>

    update: (dt) =>
      for child in *@children
        L\push child\update, dt

    get: => @children[#@children]\get!
    getc: => @children[#@children]\getc!

    __tostring: => '<dowrapper>'

  eval: (scope, tail) =>
    UpdateChildren [(expr\eval scope, @registry) or Const.empty! for expr in *tail]

{
  'op-invoke': op_invoke
  'fn-invoke': fn_invoke
  'do': do_expr

  require: require_mod
  :def, :use
  :fn
}
