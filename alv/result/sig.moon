----
-- Continuous stream of values.
--
-- @classmod SigStream
import Result, __eq from require 'alv.result.base'

class SigStream extends Result
--- Result interface
--
-- `SigStream` implements the `Result` interface.
-- @section result

  --- return whether this Result was changed in the current tick.
  -- @treturn bool
  dirty: => @updated == COPILOT.T

  --- unwrap to the Lua type.
  --
  -- Asserts `@type == type` if `type` is given.
  --
  -- @tparam[opt] type.Type type the type to check for
  -- @tparam[optchain] string msg message to throw if type don't match
  -- @treturn any `value`
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    @value

  --- create a mutable copy of this stream.
  --
  -- Used to insulate eval-cycles from each other.
  --
  -- @treturn SigStream
  fork: =>
    with @@ @type, @value
      .updated = @updated

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  --- the type of this Result's value.
  -- @tfield type.Type type

  --- the metatype string for this Result.
  -- @tfield string metatype (`~`)
  metatype: '~'

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

  --- update this stream's value.
  --
  -- Marks this stream as dirty for the remainder of the current tick.
  set: (value) =>
    if not @type\eq value, @value
      @value = value
      @updated = COPILOT.T

  --- the wrapped Lua value.
  -- @tfield any value

--- static functions
-- @section static

  --- construct a new Constant.
  --
  -- @classmethod
  -- @tparam string type the type name
  -- @tparam ?any value the Lua value to be accessed through `unwrap`
  new: (type, @value) => super type

  :__eq

{
  :SigStream
}
