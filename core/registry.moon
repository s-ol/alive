class Registry
  new: () =>
    @map = {}

-- methods for Tag

  last: (index) => @last_map[index]

  replace: (index, expr) =>
    L\trace "reg: setting #{index} to #{expr}"
    assert not @map[index], "duplicate tags with index #{index}!"
    @map[index] = expr

  init: (tag, expr) =>
    L\trace "reg: init pending to #{expr}"
    table.insert @pending, { :tag, :expr }

  active: ->
    assert Registry.active_registry, "no active Registry!"

-- public methods

  wrap: (fn) =>
    (...) ->
      @prepare!
      with fn ...
        @finalize!

  prepare: =>
    assert not @prev, "already have a previous registry? #{@prev}"
    @prev, @@active_registry = @@active_registry, @
    @last_map, @map, @pending = @map, {}, {}

  finalize: =>
    for tag, val in pairs @last_map
      if not @map[tag]
        val\destroy!

    for { :tag, :expr } in *@pending
      -- tag was solved by another pending registration
      -- (e.g. first [A] is solved, then [5.A] is solved)
      continue if tag\index!

      L\trace "assigning new tag #{value} to #{tag} #{expr}"
      tag\set @next_tag!
      @map[tag\index!] = expr

    assert @ == @@active_registry, "not the active registry!"
    @@active_registry, @prev = @prev, nil

  next_tag: => #@map + 1

class SimpleRegistry extends Registry
  new: =>
    @cnt = 1

  init: (tag, expr) =>
    tag\set @cnt
    @cnt += 1

  last: (index) =>
  replace: (index, expr) =>
  finalize: =>
    assert @ == @@active_registry, "not the active registry!"
    @@active_registry, @prev = @prev, nil

{
  :Registry
  :SimpleRegistry
}
