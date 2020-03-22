----
-- `alive` public API.
--
-- @see Value
-- @see Result
-- @see Cell
-- @see Scope
-- @see Registry
-- @see Tag
-- @field globals
-- @field parse
-- @field eval
--
-- @module init
L or= setmetatable {}, __index: => ->

import Value from require 'core.value'
import Result from require 'core.result'
import Scope from require 'core.scope'
import Error from require 'core.error'
import Registry, SimpleRegistry from require 'core.registry'
import Tag from require 'core.tag'

import Cell from require 'core.cell'
import cell, program from require 'core.parsing'

with require 'core.cycle'
  \load!

globals = Scope.from_table require 'core.builtin'

--- exports
-- @table exports
-- @tfield Value Value
-- @tfield Result Result
-- @tfield Cell Cell
-- @tfield RootCell RootCell
-- @tfield Scope Scope
-- @tfield Error Error
-- @tfield Registry Registry
-- @tfield Tag Tag
-- @tfield Scope globals global definitons
-- @tfield parse function to turn a `string` into a root `Cell`
{
  :Value, :Result
  :Cell, :RootCell
  :Scope, :Error

  :Registry, :SimpleRegistry, :Tag

  :globals

  parse: (str) ->
    assert (program\match str), Error 'syntax', "failed to parse"

  eval: (str, inject) ->
      scope = Scope nil, globals
      scope\use inject if inject

      ast = assert (program\match str), "failed to parse"
      result = ast\eval scope
      result\const!
}
