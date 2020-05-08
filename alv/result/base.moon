----
-- base Result interface.
--
-- implemented by `Constant`, `SigStream`, `EvtStream`, and `IOStream`.
--
-- @classmod Result

class Result
--- Result interface.
--
-- Methods that have to be implemented by `Result` implementations
-- (`SigStream`, `EvtStream`, `IOStream`).
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

  __tostring: => "<#{@type}#{@metatype} #{@type\pp @value}>"
  __inherited: (cls) => cls.__base.__tostring or= @__tostring

  --- the type of this Result's value.
  -- @tfield type.Type type

  --- the metatype string for this Result.
  --
  -- one of `=` (`Constant`), `~` (`SigStream`),
  -- `!` (`EvtStream` and `IOStream`).
  --
  -- @tfield string metatype

  --- get the full typestring.
  -- @treturn string `type .. metatype`
  fulltype: => (tostring @type) .. @metatype

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

{
  :Result
}
