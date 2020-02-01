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
          when Scope
            'scope'
          when Const
            return val
          else
            error "#{key}: cannot constify '#{klass.__name}' instance"
      else
        return Const 'scope', Scope.from_table val
    else
      error "#{key}: cannot constify Lua type '#{type val}'"

  Const typ, val

class Scope
  new: (@node, @parent) =>
    @values = {}

  log: (msg) => -- print msg .. " in #{@}"

  set_raw: (key, val) => @values[key] = constify val, key
  set: (key, val) =>
    @log "setting #{key} = #{val}"
    @values[key] = val

  get: (key, prefix='') =>
    @log "checking for #{key}"
    if val = @values[key]
      @log "found #{val}"
      return val

    start, rest = key\match '^(.-)/(.*)'

    if not start
      return @parent\get key

    scope = @get start
    assert scope and scope.type == 'scope', "cant find '#{prefix}#{start}' for '#{prefix}#{key}'"
    scope\getc!\get rest, "#{prefix}#{start}/"

  use: (other) =>
    for k, v in pairs other.values
      @values[k] = v

  from_table: (tbl) ->
    with Scope!
      .values = { k, constify v, k for k,v in pairs tbl }

  __tostring: =>
    buf = "<Scope"
    buf ..= "@#{@node}" if @node

    depth = -1
    parent = @parent
    while parent
      depth += 1
      parent = parent.parent
    buf ..= " ^#{depth}" if depth != 0

    buf ..= " [#{table.concat [key for key in pairs @values], ', '}]"

    buf ..= ">"
    buf


{
  :Scope
}
