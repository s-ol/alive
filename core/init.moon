L or= setmetatable {}, __index: => ->

import Op, Action, FnDef from require 'core.base'

import Const, load_ from require 'core.const'
import Scope from require 'core.scope'
load_!

import Cell, RootCell from require 'core.cell'
import cell, program from require 'core.parsing'

{
  :Const, :Cell, :RootCell
  :Op, :Action, :FnDef
  :Scope

  parse: program\match
  eval: do
    class BuiltinRegistry
      new: =>
        @last = 1

      register: (thing, tag) =>
        with tag or Const.sym "builtin.#{@last}"
          @last += 1

    registry = BuiltinRegistry!

    (str, inject) ->
      scope = Scope.from_table require 'lib.builtin'
      scope\use inject if inject

      ast = assert (cell\match str), "failed to parse: #{str}"
      Const.wrap ast\eval scope, registry
}
