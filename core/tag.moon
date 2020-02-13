import Registry from require 'core.registry'

local ClonedTag

class DummyReg
  destroy: =>

  __tostring: => "<dummy>"

dummy = DummyReg!

class Tag
  new: (@value) =>

  clone: (parent) => ClonedTag @, parent

  last: =>
    if index = @index!
      Registry.active!\last index

  keep: (expr) =>
    index = assert @index!
    assert expr == Registry.active!\last index
    Registry.active!\replace index, expr

  replace: (expr) =>
    if index = @index!
      Registry.active!\replace index, expr
    else
      Registry.active!\init @, expr

  ensure: =>
    if index = @index!
      Registry.active!\replace index, dummy, true
    else
      Registry.active!\init @, dummy

  index: => @value

  set: (value) =>
    assert not @value, "setting #{@} again"
    @value = value

  @blank: -> Tag!
  @parse: (num) => @ tonumber num

  stringify: => if @value then "[#{@value}]" else ''

  __tostring: => if @value then "#{@value}" else '[blank]'

class ClonedTag extends Tag
  new: (@original, @parent) =>

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

{
  :Tag
}
