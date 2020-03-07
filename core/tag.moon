----
-- Identity provider for `Cell`s and `Action`s.
--
-- Tags are one of:
-- - 'blank' (`[?]`, to be auto-assigned by the Copilot)
-- - literal (`[1]`)
-- - cloned (`[X.Y]`, obtained by cloning Y with parent X)
--
-- @classmod Tag
import Registry from require 'core.registry'

local ClonedTag

class DummyReg
  destroy: =>

  __tostring: => "<dummy>"

dummy = DummyReg!

class Tag
--- methods
-- @section methods

  --- obtain the registered value of the last eval-cycle.
  --
  -- Obtain the value that was previously registered (using `\keep` or
  -- `\replace`) for this tag on the last eval-cylce.
  --
  -- @treturn ?any
  last: =>
    if index = @index!
      Registry.active!\last index

  --- keep using a the value from the last eval-cycle.
  --
  -- Assert that `expr` is the value that was previously registered for this
  -- tag, and keep it for the current eval cycle. Fails for blank tags.
  --
  -- @tparam any expr the value to register
  keep: (expr) =>
    index = assert @index!
    assert expr == Registry.active!\last index
    Registry.active!\replace index, expr

  --- register `expr` for this tag for the current eval cycle.
  --
  -- Will mark blank tags for auto-assignment at the end of the eval cycle.
  --
  -- @tparam any expr the value to register
  replace: (expr) =>
    if index = @index!
      Registry.active!\replace index, expr
    else
      Registry.active!\init @, expr

  --- create a copy of this tag scoped to a `parent` tag.
  --
  -- Will mark blank tags for auto-assignment at the end of the eval cycle.
  --
  -- @tparam Tag parent the parent tag
  -- @treturn Tag the cloned tag
  clone: (parent) =>
    -- ensure this tag is registered for the current eval cycle,
    -- even if it is blank and has no associated value
    if index = @index!
      Registry.active!\replace index, dummy, true
    else
      Registry.active!\init @, dummy

    assert parent, "need parent to clone!"
    ClonedTag @, parent

  stringify: => if @value then "[#{@value}]" else ''
  __tostring: => if @value then "#{@value}" else '?'

-- internal
  new: (@value) =>

  index: => @value

  -- callback from `Registry` when the eval cycle is ending and a tag value has
  -- been generated
  set: (value) =>
    assert not @value, "#{@} is not blank"
    @value = value

--- static functions
-- @section static

  --- create a blank `Tag`.
  --
  -- @treturn Tag
  blank: -> Tag!

  --- parse a `Tag` (for Lpeg parsing).
  --
  -- @tparam string num the number-string
  -- @treturn Tag
  parse: (num) => @ tonumber num

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
