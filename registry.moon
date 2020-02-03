import Scope from require 'scope'

class Registry
  new: (@env) =>
    @globals = Scope!
    for k, v in pairs require 'lib.builtin'
      @globals\set_raw k, v

    @map = {}

  --

  gentag: => #@map + 1

  retag: (@root) =>
    scope = Scope @root, @globals

    -- first pass (outin):
    -- * expand macros (mutate scopes)
    -- * resolve symbols
    for child in *@root
      child\expand scope

    -- second pass (inout):
    -- * tag untagged exprs
    -- * destroy orphaned exprs
    seen = {}
    to_tag = for typ, node in @root\walk 'inout', false
      continue unless typ == 'Xpr'

      if node.tag
        @map[node.tag] = node
        seen[node.tag] = true
        continue

      node

    for tag, expr in pairs @map
      if not seen[tag]
        expr.value\destroy! if expr.value
        @map[tag] = nil

    for sexpr in *to_tag
      tag = @gentag!
      sexpr.tag = tag
      @map[tag] = sexpr

  patch: =>
    -- third pass (inout):
    -- * patch expressions (spawn/patch)
    for child in *@root
      child\patch @map

  --

  update: (dt) =>
    return unless @root

    -- runtime pass (inout)
    for child in *@root
      child\update dt

:Registry
