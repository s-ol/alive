class Registry
  new: (@env) =>
    @globals = {}
    @map = {}

  add_module: (name, tbl=require "lib.#{name}") =>
    for k,v in pairs tbl
      @globals["#{name}/#{k}"] = v

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

    for sexpr in @root\walk_sexpr!
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
    ref = sexpr\head!\getc!
    if sexpr.tag
      print "respawning [#{sexpr.tag}]: '#{ref}'"
    else
      print "spawning '#{ref}'"

    def = assert @globals[ref], "no such function: '#{ref}'"
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

  update: (dt) =>
    -- for tag, sexpr in pairs @map
    for sexpr in @root\walk_sexpr!
      continue unless sexpr.value

      ok, err = pcall sexpr.value.update, sexpr.value, dt
      if not ok
        print "@#{sexpr}: #{err}"

:Registry
