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

cycle = require 'alv.cycle'

version = require 'alv.version'
import Logger from require 'alv.logger'

import Primitive, Struct, Array from require 'alv.type'
import Constant, SigStream, EvtStream, IOStream from require 'alv.result'
import RTNode from require 'alv.rtnode'
import Scope from require 'alv.scope'
import Error from require 'alv.error'
import Registry, SimpleRegistry from require 'alv.registry'
import Tag from require 'alv.tag'

import Cell, RootCell from require 'alv.cell'
import program from require 'alv.parsing'

cycle\resolve!

globals = require 'alv.builtin'

cycle\resolve!

import Copilot from require 'alv.copilot'

--- exports
-- @table exports
-- @tfield version version
-- @tfield Constant Constant
-- @tfield SigStream SigStream
-- @tfield EvtStream EvtStream
-- @tfield IOStream IOStream
-- @tfield RTNode RTNode
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
  :version

  :Constant, :SigStream, :EvtStream, :IOStream
  :Cell, :RootCell
  :RTNode, :Scope, :Error

  :Primitive, :Struct, :Array

  :Registry, :SimpleRegistry, :Tag

  :globals

  :Copilot, :Logger

  parse: (str) ->
    assert (program\match str), Error 'syntax', "failed to parse"

  eval: (str, inject) ->
    scope = Scope globals
    scope\use inject if inject

    ast = assert (program\match str), "failed to parse"
    result = ast\eval scope
    result\const!
}
