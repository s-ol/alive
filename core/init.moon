L or= setmetatable {}, __index: => ->

import Value, Result, load_ from require 'core.value'
import Scope from require 'core.scope'
load_!

import Registry from require 'core.registry'
import Tag from require 'core.tag'

import Cell, RootCell from require 'core.cell'
import cell, program from require 'core.parsing'

globals = Scope.from_table require 'core.builtin'

{
  :Value, :Result
  :Cell, :RootCell
  :Scope

  :Registry, :Tag

  :globals
  parse: program\match
  eval: (str, inject) ->
      scope = Scope nil, globals
      scope\use inject if inject

      ast = assert (cell\match str), "failed to parse: #{str}"
      result = ast\eval scope
      result\const!
}
