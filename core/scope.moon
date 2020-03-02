import Result, Value from require 'core.value'

class Scope
  new: (@parent, @dynamic_parent) =>
    @values = {}

  set_raw: (key, val) =>
    value = Value.wrap val, key
    @values[key] = Result :value

  set: (key, val) =>
    L\trace "setting #{key} = #{val} in #{@}"
    assert val.__class == Result, "expected #{key}=#{val} to be Result"
    assert not @values[key], "cannot redefine symbol #{key}!"
    @values[key] = val

  recurse: (key) =>
    parent = if key\match '^%*.*%*$' then @dynamic_parent else @parent
    parent or= @parent
    return parent and L\push parent\get, key

  get: (key, prefix='') =>
    L\debug "checking for #{key} in #{@}"
    if val = @values[key]
      L\trace "found #{val} in #{@}"
      return val

    start, rest = key\match '^(.-)/(.+)'

    if not start
      return @recurse key

    child = @get start
    assert child and child.value.type == 'scope', "#{start} is not a scope (looking for #{key})"
    child.value\unwrap!\get rest, "#{prefix}#{start}/"

  use: (other) =>
    L\trace "using defs from #{other} in #{@}"
    for k, v in pairs other.values
      @values[k] = v

  from_table: (tbl) ->
    with Scope!
      for k, v in pairs tbl
        \set_raw k, v

  __tostring: =>
    buf = "<Scope"

    depth = -1
    parent = @parent
    while parent
      depth += 1
      parent = parent.parent
    buf ..= " ^#{depth}" if depth != 0

    keys = [key for key in pairs @values]
    if #keys > 5
      keys = [key for key in *keys[,5]]
      keys[6] = '...'
    buf ..= " [#{table.concat keys, ', '}]"

    buf ..= ">"
    buf

:Scope
