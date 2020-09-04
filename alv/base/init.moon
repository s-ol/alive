----
-- Base definitions for extensions.
--
-- This module exports the following classes and tables that extension modules
-- may need:
--
-- @module base
-- @see Op
-- @see PureOp
-- @see Builtin
-- @see FnDef
-- @see Input
-- @see base.match.const
-- @see base.match.sig
-- @see base.match.evt
-- @see Constant
-- @see SigStream
-- @see EvtStream
-- @see type.T
-- @see type.Primitive
-- @see type.Array
-- @see type.Struct
-- @see RTNode
-- @see Error

import Op from require 'alv.base.op'
import PureOp from require 'alv.base.pureop'
import Builtin from require 'alv.base.builtin'
import FnDef from require 'alv.base.fndef'
import Input from require 'alv.base.input'
import const, sig, evt from require 'alv.base.match'
import Constant, SigStream, EvtStream from require 'alv.result'
import T, Primitive, Array, Struct from require 'alv.type'
import RTNode from require 'alv.rtnode'
import Error from require 'alv.error'

{
  :Op, :PureOp
  :Builtin
  :FnDef
  :Input
  :const, :sig, :evt

  -- redundant exports, to keep anything an extension might need in one import

  -- Results
  :Constant, :SigStream, :EvtStream

  -- Types
  :T, :Primitive, :Array, :Struct

  :RTNode
  :Error
}
