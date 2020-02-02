import is_object from require 'moon'

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

{
  :Const
  :Op
  :Macro
}
