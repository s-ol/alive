local Const

class Scope
  new: (@node, @parent) =>
    import Const from require 'base'

    @values = {}

  set_raw: (key, val) => @values[key] = Const.wrap val, key
  set: (key, val) =>
    L\trace "setting #{key} = #{val}"
    @values[key] = val

  get: (key, prefix='') =>
    L\debug "checking for #{key} in #{@}"
    if val = @values[key]
      L\trace "found #{val} in #{@}"
      return val

    start, rest = key\match '^(.-)/(.*)'

    if not start
      return @parent and L\push -> @parent\get key

    scope = @get start
    assert scope and scope.type == 'scope', "cant find '#{prefix}#{start}' for '#{prefix}#{key}'"
    scope\getc!\get rest, "#{prefix}#{start}/"

  use: (other) =>
    for k, v in pairs other.values
      @values[k] = v

  from_table: (tbl) ->
    with Scope!
      .values = { k, Const.wrap v, k for k,v in pairs tbl }

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
