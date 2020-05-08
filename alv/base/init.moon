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
-- @see Constant
-- @see SigStream
-- @see EvtStream
-- @see IOStream
-- @see RTNode
-- @see Error

import Op from require 'alv.base.op'
import Builtin from require 'alv.base.builtin'
import FnDef from require 'alv.base.fndef'
import Input from require 'alv.base.input'
import val, evt from require 'alv.base.match'
import Constant, SigStream, EvtStream, IOStream from require 'alv.result'
import RTNode from require 'alv.rtnode'
import Error from require 'alv.error'

{
  :Op
  :Builtin
  :FnDef
  :Input
  :val, :evt

  -- redundant exports, to keep anything an extension might need in one import
  :Constant, :SigStream, :EvtStream, :IOStream
  :RTNode, :Error
}
