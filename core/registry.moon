import Const from require 'core.const'
import Scope from require 'core.scope'

local ClonedTag

class Tag
  new: (@value) =>

  clone: (parent) => ClonedTag @, parent

  last: =>
    if index = @index!
      @registry\last index

  keep: (expr) =>
    index = assert @index!
    assert expr == @registry\last index
    @registry\replace index, expr

  replace: (expr) =>
    if index = @index!
      @registry\replace index, expr
    else
      @registry\init @, expr

index: => @value

  set: (value) =>
    assert not @value, "setting #{@} again"
    @value = value

  @blank: -> Tag!
  @parse: (num) => @ tonumber num

  stringify: => if @value then "[#{@value}]" else ''

  __tostring: => if @value then "#{@value}" else '[blank]'

class ClonedTag extends Tag
  class DummyReg
    destroy: =>

  new: (@original, @parent) =>
    @registry = @original.registry
    @dummy = DummyReg!

  keep: (expr) =>
    super\keep expr
    @original.registry or= @registry
    @original\replace @dummy

  replace: (expr) =>
    super\replace expr
    @original.registry or= @registry
    @original\replace @dummy

  index: =>
    orig = @original\index!
    parent = @parent\index!
    if orig and parent
      "#{parent}.#{orig}"

  set: (value) => @original\set value

  stringify: => error "cant stringify ClonedTag"

  __tostring: =>
    if @parent
      "#{@parent}.#{@original}"
    else
      tostring @original

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

-- public methods

  prepare: =>
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

  next_tag: => #@map + 1

{
  :Tag
  :Registry
}
