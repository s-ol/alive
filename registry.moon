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
    for typ, node in @root\walk 'inout', false
      L\trace "patching #{node}"
      node\patch @map[node.tag]

  --

  tb = (msg) -> debug.traceback msg, 2
  update: (dt) =>
    for typ, sexpr in @root\walk 'inout', false
      continue unless typ == 'Xpr'

      head = sexpr\head!
      continue unless head and head.type == 'opdef'
      continue unless sexpr.value

      ok, err = xpcall sexpr.value.update, tb, sexpr.value, dt
      if not ok
        L\error "while updating #{sexpr}: #{err}"

:Registry
