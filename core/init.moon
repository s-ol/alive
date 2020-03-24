----
-- `alive` public API.
--
-- @module init
L or= setmetatable {}, __index: => ->

import ValueStream, EventStream, IOStream from require 'core.stream'
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
-- @tfield ValueStream ValueStream
-- @tfield EventStream EventStream
-- @tfield IOStream IOStream
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
  :ValueStream, :EventStream, :IOStream
  :Cell, :RootCell
  :Result, :Scope, :Error

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
