import Registry from require 'core.registry'

local ClonedTag

class DummyReg
  destroy: =>

  __tostring: => "<dummy>"

dummy = DummyReg!

class Tag
  -- obtain the value that was previously registered (using keep or replace) for
  -- this tag
  last: =>
    if index = @index!
      Registry.active!\last index

  -- assert that `expr` is the value that was previously registered for this
  -- tag, and keep it for the current eval cycle.
  -- fails for blank tags.
  keep: (expr) =>
    index = assert @index!
    assert expr == Registry.active!\last index
    Registry.active!\replace index, expr

  -- register `expr` for this tag for the current eval cycle.
  -- registers blank tags.
  replace: (expr) =>
    if index = @index!
      Registry.active!\replace index, expr
    else
      Registry.active!\init @, expr

  -- create a copy of this tag scoped to a `parent` tag.
  -- registers blank tags.
  clone: (parent) =>
    -- ensure this tag is registered for the current eval cycle,
    -- even if it is blank and has no associated value
    if index = @index!
      Registry.active!\replace index, dummy, true
    else
      Registry.active!\init @, dummy

    assert parent, "need parent to clone!"
    ClonedTag @, parent

-- internal
  new: (@value) =>

  index: => @value

  -- callback from `Registry` when the eval cycle is ending and a tag value has
  -- been generated
  set: (value) =>
    assert not @value, "#{@} is not blank"
    @value = value

-- static

  @blank: -> Tag!
  @parse: (num) => @ tonumber num

  stringify: => if @value then "[#{@value}]" else ''
  __tostring: => if @value then "#{@value}" else '?'

class ClonedTag extends Tag
  new: (@original, @parent) =>

  index: =>
    orig = @original\index!
    parent = @parent\index!
    if orig and parent
      "#{parent}.#{orig}"

  set: (value) =>
    assert @parent.value, "cloned tag #{@} set before parent"
    @original\set value

  stringify: => error "cant stringify ClonedTag"

  __tostring: =>
    if @parent
      "#{@parent}.#{@original}"
    else
      tostring @original

{
  :Tag
}
