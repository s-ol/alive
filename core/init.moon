L or= setmetatable {}, __index: => ->

import Op, Action, FnDef from require 'core.base'

import Const, load_ from require 'core.const'
import Scope from require 'core.scope'
load_!

import Cell, RootCell from require 'core.cell'

{
  :Const, :Cell, :RootCell
  :Op, :Action, :FnDef
  :Scope
}
