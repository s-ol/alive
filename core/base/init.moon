----
-- Base definitions for extensions.
--
-- This module exports the following classes and tables that extension modules
-- may need:
--
-- @module base
-- @see Op
-- @see Action
-- @see FnDef
-- @see Input
-- @see base.match.val
-- @see base.match.evt
-- @see ValueStream
-- @see EventStream
-- @see IOStream
-- @see Result
-- @see Error

import Op from require 'core.base.op'
import Action from require 'core.base.action'
import FnDef from require 'core.base.fndef'
import Input from require 'core.base.input'
import val, evt from require 'core.base.match'
import ValueStream, EventStream, IOStream from require 'core.stream'
import Result from require 'core.result'
import Error from require 'core.error'

{
  :Op
  :Action
  :FnDef
  :Input
  :val, :evt

  -- redundant exports, to keep anything an extension might need in one import
  :ValueStream, :EventStream, :IOStream
  :Result, :Error
}
