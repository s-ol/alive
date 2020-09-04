----
-- base Result interface.
--
-- implemented by `Constant`, `SigStream`, and `EvtStream`.
--
-- @classmod Result
import Type from require 'alv.type'
import ancestor from require 'alv.util'

class Result
--- Result interface.
--
-- Methods that have to be implemented by `Result` implementations
-- (`Constant`, `SigStream`, `EvtStream`).
--
-- @section interface

  --- return whether this Result was changed in the current tick.
  -- @function dirty
  -- @treturn boolean

  --- create a mutable copy of this Result.
  --
  -- Used to insulate eval-cycles from each other.
  --
  -- @function fork
  -- @treturn Result

  __tostring: =>
    if @value then
      "<#{@type}#{@metatype} #{@type\pp @value}>"
    else
      "<#{@type}#{@metatype}>"
  __inherited: (cls) => cls.__base.__tostring or= @__tostring

  --- the type of this Result's value.
  -- @tfield type.Type type

  --- the metatype string for this Result.
  --
  -- one of `=` (`Constant`), `~` (`SigStream`), `!` (`EvtStream`).
  --
  -- @tfield string metatype

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

  --- construct a new Result.
  --
  -- @classmethod
  -- @tparam type.Type type the type
  -- @tparam ?table meta the `meta` table
  new: (@type, @meta={}) =>
    assert @type and (ancestor @type.__class) == Type, "not a type: #{@type}"

{
  :Result
  __eq: (a, b) ->
    a.type == b.type and a.type\eq a.value, b.value
}
