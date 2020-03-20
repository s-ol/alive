----
-- Base definitions for extensions.
--
-- This module exports the following classes that extension modules may need:
--
-- @module base
-- @see IO
-- @see Op
-- @see Action
-- @see FnDef
-- @see Input
-- @see match
-- @see Value
-- @see Result
-- @see Error

import IO from require 'core.base.io'
import Op from require 'core.base.op'
import Action from require 'core.base.action'
import FnDef from require 'core.base.fndef'
import Input from require 'core.base.input'
import match from require 'core.base.match'
import Value from require 'core.value'
import Result from require 'core.result'
import Error from require 'core.error'

{
  :IO
  :Op
  :Action
  :FnDef
  :Input
  :match

  -- redundant exports, to keep anything an extension might need in one import
  :Value, :Result, :Error
}
