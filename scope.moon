import Const, Op from require 'base'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

local Scope

constify = (val, key) ->
  typ = switch type val
    when 'number'
      'num'
    when 'string'
      'str'
    when 'table'
      if base = rawget val, '__base'
        -- a class
        switch ancestor val
          when Op
            'opdef'
          else
            error "#{key}: cannot constify klass '#{val.__name}'"
      elseif klass = val.__class
        -- an instance
        switch ancestor klass
          when Op
            'op'
          when Const
            return val
          else
            error "#{key}: cannot constify '#{klass.__name}' instance"
      else
        return Scope.from_table val
    else
      error "#{key}: cannot constify Lua type '#{type val}'"

  Const typ, val

class Scope
  new: (@node, @parent) =>
    @values = {}

  set_raw: (key, val) => @values[key] = constify val, key
  set: (key, val) =>
    @values[key] = val

  get: (key) =>
    if val = @values[key]
      return val

    if val = @parent and @parent\get key
      return val

    part, key = key\match '^(.-)/(.*)'
    return unless part and key
    scope = assert (@get part), "no such scope: '#{key}'"
    scope\get key

  from_table: (tbl) ->
    with Scope!
      .values = { k, constify v, k for k,v in pairs tbl }

{
  :Scope
}
