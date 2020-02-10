import Const, Scope from require 'core'

class Registry
  new: () =>
    @globals = Scope!
    @globals\use Scope.from_table require 'lib.builtin'

    @prev_map = {}
    @map = {}

  --

  step: =>
    for tag, val in pairs @prev_map
      if not @map[tag]
        val\destroy!

    @prev_map, @map = @map, {}

  register: (expr, tag) =>
    tag or= @gentag!
    L\trace "registering #{expr} for tag #{tag}"
    num = tag\getc!
    if old = @map[num]
      error "double registration: #{num}\n(old: #{old}, new: #{expr})"
    @map[num] = expr
    tag

  prev: (tag) =>
    @prev_map[tag\getc!]

  gentag: =>
    num = (math.max #@map, #@prev_map) + 1

    while @map[num] or @prev_map[num]
      num += 1

    Const.num num

  eval: (ast) =>
    @map = {} -- in case we errored last time
    scope = Scope ast, @globals

    @root = ast\eval scope, @
    @step!

  --

  update: (dt) =>
    return unless @root

    @root\update dt

:Registry
