----
-- `Tag` Registry.
--
-- @classmod Registry

import Value from require 'core.value'
import Result from require 'core.result'

unpack or= table.unpack

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
    @map, @pending = {}, {}
    @tick += 1
    L\log "eval at tick #{@tick}"

    results = { pcall fn, ... }
    ok = table.remove results, 1

    if not ok
      @tick -= 1
      @release!
      L\log "rollback to tick #{@tick}"
      error unpack results
      error "WHAT?"

    for tag, val in pairs @last_map
      val\destroy! unless @map[tag]

    for { :tag, :expr } in *@pending
      -- tag was solved by another pending registration
      -- (e.g. first [A] is solved, then [5.A] is solved)
      continue if tag\index!

      next_tag = @next_tag!
      L\trace "assigned new tag #{next_tag} to #{tag} #{expr}"
      tag\set next_tag
      @map[tag\index!] = expr

    @last_map = @map
    @release!
    unpack results

  begin_eval: =>
    @latest_map = @last_map
    @begin_tick!
    @map, @pending = {}, {}

  end_eval: =>
    for tag, val in pairs @last_map
      val\destroy! unless @map[tag]

    for { :tag, :expr } in *@pending
      -- tag was solved by another pending registration
      -- (e.g. first [A] is solved, then [5.A] is solved)
      continue if tag\index!

      next_tag = @next_tag!
      L\trace "assigned new tag #{next_tag} to #{tag} #{expr}"
      tag\set next_tag
      @map[tag\index!] = expr

    @last_map = @map
    @end_tick!

  rollback_eval: =>
    @end_tick!

  next_tick: =>
    @tick += 1

  begin_tick: =>
    @grab!
    @next_tick!

  end_tick: =>
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

    results = { pcall fn, ... }
    ok = table.remove results, 1

    if not ok
      @release!
      error unpack results

    @release!
    unpack results

  grab: =>
    assert not @prev, "already have a previous registry? #{@prev}"
    @prev, Registry.active_registry = Registry.active_registry, @

  release: =>
    assert @ == Registry.active_registry, "not the active registry!"
    Registry.active_registry, @prev = @prev, nil

--- static functions
-- @section static

  --- create a new Registry.
  -- @classmethod
  new: =>
    @last_map, @map = {}, {}
    @tick = 0

  --- get the active Registry.
  --
  -- Raises an erro when there is no active Regsitry.
  --
  -- @treturn Registry
  @active: -> assert Registry.active_registry, "no active Registry!"

class SimpleRegistry extends Registry
  new: =>
    @cnt = 1
    @tick = 0

  next_tick: =>
    @tick += 1

  init: (tag, expr) =>
    tag\set @cnt
    @cnt += 1

  last: (index) =>
  replace: (index, expr) =>

  wrap: (fn) => (...) ->
    @grab!
    with fn ...
      @release!

{
  :Registry
  :SimpleRegistry
}
