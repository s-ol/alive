----
-- Stream of momentary events.
--
-- @classmod EventStream
import Stream from require 'core.stream.base'
import Result from require 'core.result'
import Error from require 'core.error'
import scope, base, registry from require 'core.cycle'

class EventStream extends Stream
--- members
-- @section members

  --- return whether this stream was changed in the current tick.
  --
  -- @treturn bool
  dirty: => @updated == registry.Registry.active!.tick

  --- push an event value into the stream.
  --
  -- Marks this stream as dirty for the remainder of the current tick.
  --
  -- @tparam any event
  add: (event) =>
    if not @dirty!
      @events = {}

    @updated = registry.Registry.active!.tick
    table.insert @events, event

  --- get the sequence of current events (if any).
  --
  -- Returns `events` if `dirty`, or an empty table otherwise.
  -- Asserts `@type == type` if `type` is given.
  --
  -- @tparam[opt] string type the type to check for
  -- @tparam[optchain] string msg message to throw if type don't match
  -- @treturn {any,...} `events`
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    if @dirty! then @events else {}

  --- create a mutable copy of this stream.
  --
  -- Used to wrap insulate eval-cycles from each other.
  --
  -- @treturn EventStream
  fork: => @@ @type

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  __tostring: =>
    "<#{@@__name} #{@type}>"

  --- Stream metatype.
  --
  -- @tfield string metatype
  metatype: 'event'

  --- the type name of the stream.
  --
  -- the following builtin typenames are used:
  --
  -- - `str` - strings, `value` is a Lua string
  -- - `sym` - symbols, `value` is a Lua string
  -- - `num` - numbers, `value` is a Lua number
  -- - `bool` - booleans, `value` is a Lua boolean
  -- - `bang` - trigger signals, `value` is a Lua boolean
  -- - `opdef` - `value` is an `Op` subclass
  -- - `builtin` - `value` is a `Builtin` subclass
  -- - `fndef` - `value` is a `FnDef` instance
  -- - `scope` - `value` is a `Scope` instance
  --
  -- @tfield string type

  --- documentation metadata.
  --
  -- an optional table containing metadata for error messages and
  -- documentation. The following keys are recognized:
  --
  -- - `name`: optional name
  -- - `summary`: single-line description (markdown)
  -- - `examples`: optional list of single-line code examples
  -- - `description`: optional full-text description (markdown)
  --
  -- @tfield ?table meta

--- static functions
-- @section static

  --- construct a new EventStream.
  --
  -- @classmethod
  -- @tparam string type the type name
  new: (type) => super type

{
  :EventStream
}
