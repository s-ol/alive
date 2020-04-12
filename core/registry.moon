----
-- `Tag` Registry.
--
-- @classmod Registry
import Result from require 'core.result'
import Error from require 'core.error'

class Registry
--- internals for `Tag`
-- @section internals

  --- lookup the last registration.
  --
  -- @tparam number|string index the registration index
  -- @treturn any
  last: (index) => @last_map[index]

  --- set the current registration.
  --
  -- @tparam string\number index the registration index
  -- @tparam any expr the registration value
  -- @tparam[default=false] boolean ignore_dup ignore duplicate registrations
  register: (index, expr, ignore_dup=false) =>
    L\trace "reg: setting #{index} to #{expr}"
    if not ignore_dup and @map[index]
      error Error 'tag', "duplicate tags [#{index}]!"
    @map[index] = expr

  --- request identity and registration for blank tag.
  --
  -- @tparam Tag tag the blank tag
  -- @tparam any expr the registration value
  init: (tag, expr) =>
    L\trace "reg: init pending to #{expr}"
    table.insert @pending, { :tag, :expr }

--- members
-- @section members

  --- begin an evaluation cycle.
  --
  -- Begin an evaltime cycle (and tick).
  -- Set the active Registry and clear out pending registrations.
  --
  -- All calls go `begin_eval` must be matched with either a call to
  -- `end_eval` or `rollback_eval`.
  begin_eval: =>
    @latest_map = @last_map
    @begin_tick!
    @map, @pending = {}, {}

  --- end an evaluation cycle.
  --
  -- Register all pending `Tag`s and destroy all orphaned registrations.
  -- Unset the active Registry.
  end_eval: =>
    for tag, val in pairs @last_map
      val\destroy! unless @map[tag]

    for { :tag, :expr } in *@pending
      -- tag was solved by another pending registration
      -- (e.g. first [A] is solved, then [5.A] is solved)
      continue if tag\index!

      next_tag = #@map + 1
      L\trace "assigned new tag #{next_tag} to #{tag} #{expr}"
      tag\set next_tag
      @map[tag\index!] = expr

    @last_map = @map
    @end_tick!

  --- abort an evaluation cycle.
  --
  -- Unset the active Registry.
  rollback_eval: =>
    @end_tick!

  --- begin a run cycle.
  --
  -- Increment the tick index and set the active Registry.
  begin_tick: =>
    @grab!
    @next_tick!

  --- end a run cycle.
  --
  -- Unset the active Registry.
  end_tick: =>
    @release!

  --- manually increment the tick index (for testing).
  next_tick: =>
    @tick += 1

  --- set the active Registry.
  grab: =>
    assert not @prev, "already have a previous registry? #{@prev}"
    @prev, Registry.active_registry = Registry.active_registry, @

  --- unset the active Registry.
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
  register: (index, expr) =>

  wrap: (fn) => (...) ->
    @grab!
    with fn ...
      @release!

{
  :Registry
  :SimpleRegistry
}
