----
-- Mapping from `sym`s to `RTNode`s.
--
-- @classmod Scope
import Constant from require 'alv.result'
import RTNode from require 'alv.rtnode'
import Error from require 'alv.error'
import T from require 'alv.type'
import opairs from require 'alv.util'

class Scope
--- members
-- @section members

  --- set a Lua value in the scope.
  --
  -- wraps `val` in a `Constant` and `RTNode` before calling `set`.
  --
  -- @tparam string key
  -- @tparam any val
  set_raw: (key, val) =>
    result = Constant.wrap val, key
    @set key, RTNode :result

  --- set a symbol to a `RTNode`.
  --
  -- @tparam string key
  -- @tparam RTNode val
  set: (key, val) =>
    L\trace "setting #{key} = #{val} in #{@}"
    assert val.__class == RTNode, "expected #{key}=#{val} to be RTNode"
    assert val.result, Error 'type', "cannot define symbol to nil"
    assert not @values[key], Error 'type', "cannot redefine symbol '#{key}'!"
    @values[key] = val

  recurse: (key) =>
    parent = if key\match '^%*.*%*$' then @dynamic_parent else @parent
    parent or= @parent
    if parent
      L\push parent\get, key
    else
      error Error 'reference', "undefined symbol '#{key}'"

  --- resolve a key in this Scope.
  --
  -- @tparam string key the key to resolve
  -- @treturn ?RTNode the value of the definition that was found, or `nil`
  get: (key) =>
    L\debug "checking for #{key} in #{@}"
    if val = @values[key]
      L\trace "found #{val} in #{@}"
      return val

    start, rest = key\match '^(.-)/(.+)'
    if not start
      return @recurse key

    child = @get start
    if not child
      error Error 'reference', "undefined symbol '#{start}'"
    if child\type! != T.scope
      error Error 'reference', "'#{start}' is not a scope"
    child.result!\get rest, while_msg

  --- copy definitions from another scope.
  --
  -- copies all definitions from `other`. Does not copy inherited definitions.
  --
  -- @tparam Scope other
  use: (other) =>
    L\trace "using defs from #{other} in #{@}"
    for k, v in pairs other.values
      @set k, v

  __tostring: =>
    buf = "<Scope"

    depth = -1
    parent = @parent
    while parent
      depth += 1
      parent = parent.parent
    buf ..= " ^#{depth}" if depth != 0

    keys = [key for key in opairs @values]
    if #keys > 5
      keys = [key for key in *keys[,5]]
      keys[6] = '…'
    buf ..= " [#{table.concat keys, ', '}]"

    buf ..= ">"
    buf

--- static functions
-- @section static

  --- create a new Scope.
  --
  -- @classmethod
  -- @tparam[opt] Scope parent a parent this scope inherits definitions from
  -- @tparam[opt] Scope dynamic_parent a parent scope that should be checked for
  -- dynamic definitions
  new: (@parent, @dynamic_parent) =>
    @values = {}

  --- convert a Lua table to a Scope.
  --
  -- `tbl` may contain more tables (or `Scope`s).
  -- Uses `Constant.wrap` on the values recursively.
  --
  -- @tparam table tbl the table to convert
  -- @treturn Scope
  @from_table: (tbl) ->
    with Scope!
      for k, v in pairs tbl
        if type(v) == 'table' and v.__class == RTNode
          \set k, v
        else
          \set_raw k, v

{
  :Scope
}
