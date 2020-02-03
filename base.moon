import is_object from require 'moon'
import Scope from require 'scope'

class Op
  new: (...) =>
    @setup ...

  update: (dt) =>

  get: => @value
  getc: =>
    L\warn "stream #{@} cast to constant"
    @value

  destroy: =>

  __tostring: => "<op: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

  spawn: (Opdef, ...) ->
    Opdef ...

class Macro
  new: (@node) =>
    -- print "creating Macro #{@@__name}", debug.traceback!

  -- forwarded from ASTNode
  -- `scope` is the parent scope.
  -- should :expand or :expand_quoted all subexprs
  -- should return `Const` of `forward` if it has a value
  expand: (scope) =>
    L\trace "expanding #{@}"
    for child in *@node[2,]
      L\push child\expand, @node.scope

    nil

  -- forwarded from ASTNode
  -- should dispatch :patch on all :expanded subexprs
  -- should setup @value if it is an Op
  patch: (map) =>
    L\trace "patching #{@}"
    for child in *@node[2,]
      L\push child\patch, map

  -- forwarded from ASTNode
  -- should dispatch :update on all :expanded subexprs and @node.value
  update: (dt) =>
    L\trace "updating #{@}"
    for child in *@node[2,]
      L\push child\update, dt

    @node.value\update dt if @node.value

  -- forwarded from ASTNode
  -- should dispatch :destroy to all allocated Ops
  destroy: =>
    L\trace "destroying #{@}"
    @node.value\destroy! if @node.value

  __tostring: => "<macro: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

class Forward
  new: (@node) =>

  get: => (assert @node.value, "node never patched! #{@}")\get!
  getc: => (assert @node.value, "node never patched! #{@}")\getc!

  update: =>
  destroy: =>

  __tostring: => "<fwd: #{@node}>"

class Const
  types = {
    sym: true
    scope: true
    str: true
    num: true
    op: true
    opdef: true
    macrodef: true
  }
  new: (@type, @value) =>
    assert types[@type], "invalid Const type: #{@type}"

  get: => @value
  getc: => @value

  update: =>
  destroy: =>

  __tostring: =>
    value = if @type\match 'def$' then @value.__name else @value
    "<#{@type}: #{value}>"

  ancestor = (klass) ->
    assert klass, "cant find the ancestor of nil"
    while klass.__parent
      klass = klass.__parent
    klass
  wrap: (val, name='(unknown)') ->
    typ = switch type val
      when 'number' then 'num'
      when 'string' then 'str'
      when 'table'
        if base = rawget val, '__base'
          -- a class
          switch ancestor val
            when Op then 'opdef'
            when Macro then 'macrodef'
            else
              error "#{name}: cannot wrap class '#{val.__name}'"
        elseif klass = val.__class
          -- an instance
          switch ancestor klass
            when Op then 'op'
            when Scope then 'scope'
            when Const, Forward
              return val
            else
              error "#{name}: cannot wrap '#{klass.__name}' instance"
        else
          -- plain table
          return Const 'scope', Scope.from_table val
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Const typ, val

{
  :Op
  :Macro
  :Forward
  :Const
}
