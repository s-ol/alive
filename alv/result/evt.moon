----
-- Stream of momentary events.
--
-- @classmod EvtStream
import Result from require 'alv.result.base'

class EvtStream extends Result
--- Result interface
--
-- `EvtStream` implements the `Result` interface.
-- @section result

  --- return whether this Result was changed in the current tick.
  -- @treturn bool
  dirty: => @updated == COPILOT.T

  --- get the sequence of current events (if any).
  --
  -- Returns `events` if `dirty`, or an empty table otherwise.
  -- Asserts `@type == type` if `type` is given.
  --
  -- @tparam[opt] type.Type type the type to check for
  -- @tparam[optchain] string msg message to throw if type don't match
  -- @treturn {any,...} `events`
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    if @dirty! then @events else {}

  --- create a mutable copy of this stream.
  --
  -- Used to wrap insulate eval-cycles from each other.
  --
  -- @treturn EvtStream
  fork: => @@ @type

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  __tostring: =>
    events = table.concat [@type\pp e for e in *@events], ' '
    "<#{@type}#{@metatype} #{events}>"

  --- the type of this Result's value.
  -- @tfield type.Type type

  --- the metatype string for this Result.
  -- @tfield string metatype (`!`)
  metatype: '!'

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

--- members
-- @section members

  --- push an event value into the stream.
  --
  -- Marks this stream as dirty for the remainder of the current tick.
  add: (event) =>
    if not @dirty!
      @events = {}

    @updated = COPILOT.T
    table.insert @events, event

  --- the wrapped Lua value.
  -- @tfield {any,...} events

--- static functions
-- @section static

  --- construct a new EvtStream.
  --
  -- @classmethod
  -- @tparam type.Type type the type
  new: (type) =>
    super type
    @events = {}

{
  :EvtStream
}
