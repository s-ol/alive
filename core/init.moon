L or= setmetatable {}, __index: => ->

import Op, Action, FnDef from require 'core.base'

import Const, load_ from require 'core.const'
import Scope from require 'core.scope'
load_!

import Registry from require 'core.registry'

import Cell, RootCell from require 'core.cell'
import cell, program from require 'core.parsing'

globals = Scope.from_table require 'core.builtin'

{
  :Const, :Cell, :RootCell
  :Op, :Action, :FnDef
  :Scope

  :Registry
  :globals

  parse: program\match
  eval: do
    class BuiltinRegistry
      new: =>
        @cnt = 1

      init: (tag, expr) =>
        tag\set @cnt
        @cnt += 1

      last: (index) =>
      replace: (index, expr) =>

    registry = BuiltinRegistry!

    (str, inject) ->
      scope = Scope nil, globals
      scope\use inject if inject

      ast = assert (cell\match str), "failed to parse: #{str}"
      Const.wrap ast\eval scope, registry
}
