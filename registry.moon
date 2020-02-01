import Scope from require 'scope'

class Registry
  new: (@env) =>
    @globals = Scope!
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
    @root\expand scope

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
    def = sexpr\head!\getc!
    if sexpr.tag
      print "respawning [#{sexpr.tag}]: '#{def}'"
    else
      print "spawning '#{def}'"

    sexpr.value = def sexpr

  patch_expr: (new, old) =>
    if new\head!\getc! == old\head!\getc!
      -- same function, can be patched
      print "patching [#{new.tag}]"
      new.value = old.value
      new.value\patch new
    else
      -- different function
      @spawn_expr new

  destroy_expr: (sexpr) =>
    sexpr.value\destroy!
    print "destroying [#{sexpr.tag}]"

  --

  tb = (msg) -> debug.traceback msg, 2
  update: (dt) =>
    -- for tag, sexpr in pairs @map
    for typ, sexpr in @root\walk 'inout', false
      continue unless typ == 'Xpr'
      continue unless sexpr.value

      ok, err = xpcall sexpr.value.update, tb, sexpr.value, dt
      if not ok
        print "@#{sexpr}: #{err}"

:Registry
