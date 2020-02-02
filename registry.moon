import Scope from require 'scope'

class Registry
  new: (@env) =>
    @globals = Scope!
    for k, v in pairs require 'lib.builtin'
      @globals\set_raw k, v

    @map = {}

  add_module: (name) =>
    @globals\set_raw name, require "lib.#{name}"

  --

  gentag: => #@map + 1

  patch: (sexpr) =>
    old = @map[sexpr.tag]
    @map[sexpr.tag] = sexpr

    if not old
      @spawn_expr sexpr
    else
      @patch_expr sexpr, old
    sexpr.tag

  patch_root: (@root) =>
    seen = {}
    to_tag = {}

    scope = Scope @root, @globals
    for child in *@root
      child\expand scope

    for typ, node in @root\walk 'inout', false
      node\link!

      continue unless typ == 'Xpr'
      sexpr = node

      if not sexpr.tag
        @spawn_expr sexpr
        table.insert to_tag, sexpr
      else
        tag = @patch sexpr
        seen[tag] = true

    for sexpr in *to_tag
      tag = @gentag!
      sexpr.tag = tag
      @map[tag] = sexpr
      seen[tag] = true

    for tag, expr in pairs @map
      if not seen[tag]
        @destroy_expr expr
        @map[tag] = nil

  spawn_expr: (sexpr) =>
    head = sexpr\head!
    return if head.type == 'macro'

    def = head\getc!
    if sexpr.tag
      print "respawning [#{sexpr.tag}]: '#{def}'"
    else
      print "spawning '#{def}'"

    sexpr.value = def sexpr

  patch_expr: (new, old) =>
    head = new\head!

    if head\getc! == old\head!\getc!
      -- same function, can be patched
      return if head.type == 'macro'

      print "patching [#{new.tag}]"
      new.value = old.value
      new.value\patch new
    else
      -- different function
      @spawn_expr new

  destroy_expr: (sexpr) =>
    head = sexpr\head!
    return if head.type == 'macro'

    sexpr.value\destroy!
    print "destroying [#{sexpr.tag}]"

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
        print "@#{sexpr}: #{err}"

:Registry
