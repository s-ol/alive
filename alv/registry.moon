----
-- `Tag` Registry.
--
-- @classmod Registry
import Result from require 'alv.result'
import Error from require 'alv.error'

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
  -- @tparam Tag tag the Tag to register
  -- @tparam any expr the registration value
  -- @tparam[default=false] boolean ignore_dup ignore duplicate registrations
  register: (tag, expr, ignore_dup=false) =>
    index = tag\index!

    if index and (not @map[index] or ignore_dup)
      L\trace "reg: setting #{index} to #{expr}"
      @map[index] = expr
    else
      if index
        L\warn "duplicate tag [#{index}], reassigning repeated occurance"
        tag\set nil
      else
        L\trace "reg: init #{tag} to #{expr}"
      table.insert @pending, { :tag, :expr }

--- members
-- @section members

  --- begin an evaluation cycle.
  --
  -- Set the active Registry and clear out pending registrations.
  --
  -- All calls go `begin_eval` must be matched with either a call to
  -- `end_eval` or `rollback_eval`.
  begin_eval: =>
    @grab!
    assert not @map, "unfinished evaluation cycle"
    @map, @pending = {}, {}

  --- abort an evaluation cycle.
  --
  -- Unset the active Registry.
  rollback_eval: =>
    for { :tag, :expr } in *@pending
      expr\destroy!

    @map, @pending = nil, nil

  --- end an evaluation cycle.
  --
  -- Register all pending `Tag`s and destroy all orphaned registrations.
  -- Unset the active Registry.
  -- @treturn bool whether any changes to the AST were made
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

    dirty = #@pending > 0
    @last_map, @map, @pending = @map, nil, nil

    dirty

  --- set the active Registry.
  grab: =>
    assert not @prev, "already have a previous registry? #{@prev}"
    @prev, Registry.active_registry = Registry.active_registry, @

  --- unset the active Registry.
  release: =>
    assert @ == Registry.active_registry, "not the active registry!"
    Registry.active_registry, @prev = @prev, nil

  --- destroy this Registry and all associated Registrations.
  -- needs to be called *after* `:eval`.
  destroy: =>
    assert not @tag, "unfinished evaluation cycle"
    for tag, val in pairs @last_map
      val\destroy!

    @last_map = {}

--- static functions
-- @section static

  --- create a new Registry.
  -- @classmethod
  new: =>
    @last_map = {}

  --- get the active Registry.
  --
  -- Raises an error when there is no active Registry.
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
  register: (index, expr) =>

  wrap: (fn) => (...) ->
    @grab!
    with fn ...
      @release!

{
  :Registry
  :SimpleRegistry
}
