import Value from require 'core.value'

class Scope
  new: (@node, @parent) =>
    @values = {}

  set_raw: (key, val) => @values[key] = Value.wrap val, key
  set: (key, val) =>
    L\trace "setting #{key} = #{val} in #{@}"
    @values[key] = val

  get: (key, prefix='') =>
    L\debug "checking for #{key} in #{@}"
    if val = @values[key]
      L\trace "found #{val} in #{@}"
      return val

    start, rest = key\match '^(.-)/(.+)'

    if not start
      return @parent and L\push -> @parent\get key

    scope = @get start
    assert scope and scope.type == 'scope', "cant find '#{prefix}#{start}' for '#{prefix}#{key}'"
    scope\unwrap!\get rest, "#{prefix}#{start}/"

  use: (other) =>
    L\trace "using defs from #{other} in #{@}"
    for k, v in pairs other.values
      @values[k] = v

  from_table: (tbl) ->
    with Scope!
      .values = { k, Value.wrap v, k for k,v in pairs tbl }

  __tostring: =>
    buf = "<Scope"
    buf ..= "@#{@node}" if @node

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
