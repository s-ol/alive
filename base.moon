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
  expand: (scope) =>

  -- forwarded from ASTNode
  -- note: if prev_value is passed, it has to be :destroy'ed or returned
  patch: (prev_value) => prev_value

  __tostring: => "<macro: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

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
            when Const
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
  :Const
}
