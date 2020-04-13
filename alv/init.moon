----
-- `alive` public API.
--
-- @module init
if _VERSION == 'Lua 5.1'
  export assert
  assert = (a, msg, ...) ->
    if not a
      error msg
    a, msg, ...

import Logger from require 'alv.logger'
import ValueStream, EventStream, IOStream from require 'alv.stream'
import Result from require 'alv.result'
import Scope from require 'alv.scope'
import Error from require 'alv.error'
import Registry, SimpleRegistry from require 'alv.registry'
import Tag from require 'alv.tag'

import Cell, RootCell from require 'alv.cell'
import program from require 'alv.parsing'

with require 'alv.cycle'
  \load!

import Copilot from require 'alv.copilot'
globals = Scope.from_table require 'alv.builtin'

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
-- @tfield Copilot Copilot
-- @tfield Logger Logger
-- @tfield Scope globals global definitons
-- @tfield parse function to turn a `string` into a root `Cell`
{
  :ValueStream, :EventStream, :IOStream
  :Cell, :RootCell
  :Result, :Scope, :Error

  :Registry, :SimpleRegistry, :Tag

  :globals

  :Copilot, :Logger

  parse: (str) ->
    assert (program\match str), Error 'syntax', "failed to parse"

  eval: (str, inject) ->
      scope = Scope nil, globals
      scope\use inject if inject

      ast = assert (program\match str), "failed to parse"
      result = ast\eval scope
      result\const!
}
