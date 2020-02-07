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

  eval: (ast) =>
    scope = Scope ast, @globals

    @root = ast\eval scope, @
    @step!

  --

  update: (dt) =>
    return unless @root

    @root\update dt

:Registry
