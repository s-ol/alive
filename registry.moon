import Scope from require 'scope'
import Const from require 'base'

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
    @map[tag\getc 'num'] = expr
    tag

  prev: (tag) =>
    @prev_map[tag\getc 'num']

  gentag: =>
    num = (math.max #@map, #@prev_map) + 1

    while @map[num] or @prev_map[num]
      num += 1

    Const.num num

  retag: (@root) =>
    scope = Scope @root, @globals

    @prev, @next, @tmp = @next, {}, {}

    -- first pass (outin):
    -- * expand macros (mutate scopes)
    -- * resolve symbols
    -- * :register exprs
    for child in *@root
      child\expand scope, @

    -- destroy removed expr values
    for tag, expr in pairs @prev
      if not @next[i]
        expr.value\destroy! if expr.value

    -- upgrade tmp tags
    for _, expr in pairs @tmp
      tag = @gentag!
      expr.tag = tag
      @next[tag] = expr

  patch: =>
    -- third pass (inout):
    -- * patch expressions (spawn/patch)
    for child in *@root
      child\patch @

  --

  update: (dt) =>
    return unless @root

    -- runtime pass (inout)
    for child in *@root
      child\update dt

:Registry
