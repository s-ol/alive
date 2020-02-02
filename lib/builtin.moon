import Macro, Const from require 'base'
import Scope from require 'scope'

class def extends Macro
  expand: (scope) =>
    assert #@node > 2, "'def' requires at least 3 arguments"
    assert #@node % 2 == 1, "'def' requires an even number of arguments"

    L\trace @
    L\push ->
      for i=2,#@node,2
        name, val = @node[i], @node[i+1]
        assert name.atom_type == 'sym', "'def's argument ##{i} has to be a symbol"
        val\expand @node.scope
        scope\set name.raw, val.value

    nil

class _require extends Macro
  expand: (scope) =>
    assert #@node == 2, "'require' takes only one parameter"

    L\trace @
    L\push ->
      for child in *@node[2,]
        child\expand @node.scope

    name = @node\tail!
    assert name.type == 'str', "'require' only works on strings"

    L\trace @, "loading module #{name}"
    scope = Scope.from_table require "lib.#{name\getc!}"
    Const 'scope', scope

class use extends Macro
  expand: (scope) =>
    L\trace @
    L\push ->
      for child in *@node[2,]
        value = child\expand @node.scope
        L\trace @, "merging #{value} into #{scope}"
        assert value.type == 'scope', "'use' only works on scopes"
        scope\use value\getc!

    nil

{
  :def
  require: _require
  :use
}
