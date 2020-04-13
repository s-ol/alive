----
-- Base definitions for extensions.
--
-- This module exports the following classes and tables that extension modules
-- may need:
--
-- @module base
-- @see Op
-- @see Builtin
-- @see FnDef
-- @see Input
-- @see base.match.val
-- @see base.match.evt
-- @see ValueStream
-- @see EventStream
-- @see IOStream
-- @see Result
-- @see Error

import Op from require 'alv.base.op'
import Builtin from require 'alv.base.builtin'
import FnDef from require 'alv.base.fndef'
import Input from require 'alv.base.input'
import val, evt from require 'alv.base.match'
import ValueStream, EventStream, IOStream from require 'alv.stream'
import Result from require 'alv.result'
import Error from require 'alv.error'

{
  :Op
  :Builtin
  :FnDef
  :Input
  :val, :evt

  -- redundant exports, to keep anything an extension might need in one import
  :ValueStream, :EventStream, :IOStream
  :Result, :Error
}
