----
-- Identity provider for `Cell`s and `Builtin`s.
--
-- Tags are one of:
-- - 'blank' (`[?]`, to be auto-assigned by the Copilot)
-- - literal (`[1]`)
-- - cloned (`[X.Y]`, obtained by cloning Y with parent X)
--
-- @classmod Tag
import Registry from require 'alv.registry'

local ClonedTag

class DummyReg
  destroy: =>

  __tostring: => "<dummy>"

dummy = DummyReg!

class Tag
--- members
-- @section members

  --- obtain the registered value of the last eval-cycle.
  --
  -- Obtain the value that was previously registered  for this tag on the last
  -- eval-cylce.
  --
  -- @treturn ?any
  last: =>
    if index = @index!
      Registry.active!\last index

  --- register `expr` for this tag for the current eval cycle.
  --
  -- Will mark blank tags for auto-assignment at the end of the eval cycle.
  --
  -- @tparam any expr the value to register
  register: (expr) => Registry.active!\register @, expr

  --- create a copy of this tag scoped to a `parent` tag.
  --
  -- Will mark blank tags for auto-assignment at the end of the eval cycle.
  --
  -- @tparam Tag parent the parent tag
  -- @treturn Tag the cloned tag
  clone: (parent) =>
    -- ensure this tag is registered for the current eval cycle,
    -- even if it is blank and has no associated value
    Registry.active!\register @, dummy, true

    assert parent, "need parent to clone!"
    ClonedTag @, parent

  stringify: => if @value then "[#{@value}]" else ''
  __tostring: => if @value then "#{@value}" else '?'

--- internals for `Registry`
-- @section internals

  new: (@value) =>

  --- get a unique index value for this Tag.
  --
  -- The index is equal to `value` for simple tags and a path-like string for
  -- cloned tags.
  --
  -- @treturn ?number|string
  index: => @value

  --- callback to set value for blank tags.
  --
  -- `value` may be blank to reassign duplicate tags.
  --
  -- @tparam ?number value
  set: (value) =>
    either_or = (@value or value) and not (@value and value)
    assert either_or, "unexpected :set #{value} on #{@}"
    @value = value

--- static functions
-- @section static

  --- create a blank `Tag`.
  --
  -- @treturn Tag
  @blank: -> Tag!

  --- parse a `Tag` (for Lpeg parsing).
  --
  -- @tparam string num the number-string
  -- @treturn Tag
  @parse: (num) -> Tag tonumber num

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
