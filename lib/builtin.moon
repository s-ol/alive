import Const from require 'base'
import Scope from require 'scope'

module = {
  def: (scope, xpr) ->
    assert #xpr > 2, "'def' requires at least 3 arguments"
    assert #xpr % 2 == 1, "'def' requires an even number of arguments"
    for i=2,#xpr,2
      assert xpr[i].atom_type == 'sym', "'def's argument ##{i} has to be a symbol"
      xpr[i+1]\expand xpr.scope
      scope\set xpr[i].raw, xpr[i+1].value

  use: (scope, xpr) ->
    for value in *xpr[2,]
      value\expand xpr.scope
      assert value.value.type == 'scope', "'use' only works on scopes"
      scope\use value.value\getc!

  require: (scope, xpr) ->
    assert #xpr == 2, "'require' takes only one parameter"

    xpr[2]\expand xpr.scope
    name = xpr[2].value
    assert name.type == 'str', "'require' only works on strings"

    xpr.value = Const 'scope', Scope.from_table require "lib.#{name\getc!}"
}

{ k, Const 'macro', v for k, v in pairs module }
