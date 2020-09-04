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

import T, Primitive, Struct, Array from require 'alv.type'
import Constant, SigStream, EvtStream from require 'alv.result'
import RTNode from require 'alv.rtnode'
import Scope from require 'alv.scope'
import Error from require 'alv.error'
import Registry, SimpleRegistry from require 'alv.registry'
import Tag from require 'alv.tag'

import Cell, RootCell from require 'alv.cell'
import program from require 'alv.parsing'

cycle\resolve!

globals = require 'alv.builtins'

cycle\resolve!

--- exports
-- @table exports
-- @tfield version version
-- @tfield Constant Constant
-- @tfield SigStream SigStream
-- @tfield EvtStream EvtStream
-- @tfield type.T T
-- @tfield type.Primitive Primitive
-- @tfield type.Array Array
-- @tfield type.Struct Struct
-- @tfield RTNode RTNode
-- @tfield Cell Cell
-- @tfield RootCell RootCell
-- @tfield Scope Scope
-- @tfield Error Error
-- @tfield Registry Registry
-- @tfield Tag Tag
-- @tfield Logger Logger
-- @tfield Scope globals global definitons
-- @tfield parse function to turn a `string` into a root `Cell`
{
  :version

  :Constant, :SigStream, :EvtStream
  :Cell, :RootCell
  :RTNode, :Scope, :Error

  :T, :Primitive, :Struct, :Array

  :Registry, :SimpleRegistry, :Tag
  :Logger

  :globals

  parse: (str) ->
    assert (program\match str), Error 'syntax', "failed to parse"

  eval: (str, inject) ->
    scope = Scope globals
    scope\use inject if inject

    ast = assert (program\match str), "failed to parse"
    result = ast\eval scope
    result\const!
}
