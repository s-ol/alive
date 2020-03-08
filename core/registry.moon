----
-- `Tag` Registry.
--
-- @classmod Registry

import Value from require 'core.value'
import Result from require 'core.result'

class Registry
-- methods for Tag

  last: (index) => @last_map[index]

  replace: (index, expr, ignore_dup=false) =>
    L\trace "reg: setting #{index} to #{expr}"
    assert not @map[index] or ignore_dup, "duplicate tags with index #{index}!"
    @map[index] = expr

  init: (tag, expr) =>
    L\trace "reg: init pending to #{expr}"
    table.insert @pending, { :tag, :expr }

  next_tag: => #@map + 1

--- members
-- @section members

  --- wrap a function with an eval-cycle.
  --
  -- Sets the active Registry and destroys unused `Action`s and `Op`s.
  --
  -- @tparam function fn
  -- @treturn function `fn` wrapped with eval-cycle logic
  wrap_eval: (fn) => (...) ->
    @grab!
    @last_map, @map, @pending = @map, {}, {}

    with fn ...
      for tag, val in pairs @last_map
        if not @map[tag]
          val\destroy!

      for { :tag, :expr } in *@pending
        -- tag was solved by another pending registration
        -- (e.g. first [A] is solved, then [5.A] is solved)
        continue if tag\index!

        next_tag = @next_tag!
        L\trace "assigned new tag #{next_tag} to #{tag} #{expr}"
        tag\set next_tag
        @map[tag\index!] = expr

      @release!

  --- wrap a function with a tick.
  --
  -- Sets the active Registry and increments the global tick count.
  --
  -- @tparam function fn
  -- @treturn function `fn` wrapped with tick logic
  wrap_tick: (fn) => (...) ->
    @grab!
    @tick += 1
    @kr.value\set true

    for io in pairs @io
      io\tick!

    with fn ...
      @release!

  grab: =>
    assert not @prev, "already have a previous registry? #{@prev}"
    @prev, @@active_registry = @@active_registry, @

  release: =>
    assert @ == @@active_registry, "not the active registry!"
    @@active_registry, @prev = @prev, nil

--- static functions
-- @section static

  --- create a new Registry.
  -- @classmethod
  new: =>
    @map = {}
    @io = {}

    @tick = 0
    @kr = Result value: Value.bool true

  --- get the active Registry.
  --
  -- Raises an erro when there is no active Regsitry.
  --
  -- @treturn Registry
  @active: -> assert Registry.active_registry, "no active Registry!"

class SimpleRegistry extends Registry
  new: =>
    @cnt = 1

  init: (tag, expr) =>
    tag\set @cnt
    @cnt += 1

  last: (index) =>
  replace: (index, expr) =>

{
  :Registry
  :SimpleRegistry
}
