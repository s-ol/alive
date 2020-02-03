import Macro, Const, Forward from require 'base'
import Scope from require 'scope'

-- (def sym1 val-expr1
--     [sym2 val-expr2]...)
--
-- declare symbols in parent scope
--
-- if val-expr is a expand-time constant, defines a `Const`,
-- otherwise places a `Forward` for the expr
class def extends Macro
  expand: (scope) =>
    L\trace "expanding #{@}"
    assert #@node > 2, "'def' requires at least 3 arguments"
    assert #@node % 2 == 1, "'def' requires an even number of arguments"

    L\push ->
      for i=2,#@node,2
        name, val_expr = @node[i], @node[i+1]
        assert name.atom_type == 'sym', "'def's argument ##{i} has to be a symbol"
        name = name\expand_quoted!\getc!

        scope\set name, val_expr\expand @node.scope

        -- @TODO: expand to Forward in Xpr:expand
        -- if val = val_expr\expand @node.scope
        --   -- expand-time constant
        --   scope\set name, val
        -- else
        --   -- patch-time expression
        --   scope\set name, Forward val_expr
    nil

  patch: (map) =>
    L\trace "patching #{@}"
    for child in *@node[3,,2]
      L\push child\patch, map

  update: (dt) =>
    L\trace "updating #{@}"
    for child in *@node[3,,2]
      L\push child\update, dt

-- (require name-str)
--
-- require a lua module and return its `Scope`
-- name-str has to be an expand-time constant
class _require extends Macro
  expand: (scope) =>
    L\trace "expanding #{@}"
    assert #@node == 2, "'require' takes only one parameter"
    for child in *@node[2,]
      L\push child\expand, @node.scope

    name = @node\tail!
    assert name.type == 'str', "'require' only works on strings"

    L\trace @, "loading module #{name}"
    scope = Scope.from_table require "lib.#{name\getc!}"
    Const 'scope', scope

-- (use scope1 [scope2]...)
--
-- merge scopes into parent scope
-- scopes have to be expand-time constants
class use extends Macro
  expand: (scope) =>
    L\trace "expanding #{@}"
    for child in *@node[2,]
      value = L\push child\expand, @node.scope
      L\trace @, "merging #{value} into #{scope}"
      assert value.type == 'scope', "'use' only works on scopes"
      scope\use value\getc!

    nil

-- ((fn ...) arg-expr1 [arg-expr2]...)
--
-- invoke a function
class FunctionInvocation extends Macro
  new: (@node, @params, @body_tpl) =>
    super @node

  expand: (scope) =>
    L\trace "expanding #{@}"
    assert (#@params + 1) == #@node, "argument count mismatch in #{@node[1]}"

    for i=1,#@params
      param = @params[i]\getc!
      argument = @node[i+1]
      L\trace "EXPANDING ARG", argument
      @node.scope\set param, L\push argument\expand, scope

    @body = @body_tpl\clone @node.tag
    val = @body\expand @node.scope
    val

  patch: (map) =>
    L\trace "patching #{@}:"
    for child in *@node[2,]
      L\push child\patch, map

    @body\patch map

  update: (dt) =>
    L\trace "updating #{@}:"
    @body\update dt

    for child in *@node[2,]
      L\push child\update, dt

  destroy: (dt) =>
    L\trace "destroying #{@}"
    @body.value\destroy! if @body.value

  mt = { __call: (...) => @call ... }
  with_def: (params, body) ->
    call = (node) => FunctionInvocation node, params, body
    setmetatable { :call, __name: 'Invocation' }, mt

-- (fn (p1 [p2]...) body-expr)
--
-- declare a function
--
-- pX are symbols that will resolve to a 'Forward' in the body
class fn extends Macro
  expand: (scope) =>
    L\trace "expanding #{@}"
    assert #@node == 3, "'fn' takes exactly three arguments"
    params, body = @node[2], @node[3]

    assert params.type == 'Xpr', "'fn's first argument has to be an expression"
    param_symbols = for param in *params
      assert param.atom_type == 'sym', "function parameter declaration has to be a symbol"
      param\expand_quoted!

    Const 'macrodef', FunctionInvocation.with_def param_symbols, body

  patch: (map) =>
    L\trace "patching #{@}"

  update: (dt) =>

{
  :def
  require: _require
  :use
  :fn
}
