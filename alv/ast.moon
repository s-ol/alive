----
-- AST Node Interface.
--
-- implemented by `Constant` and `Cell`.
--
-- @classmod AST

--- members
-- @section members

  --- evaluate this AST Node.
  --
  -- Evaluate this node and return a `RTNode`.
  --
  -- @function eval
  -- @tparam Scope scope the scope to evaluate in
  -- @treturn RTNode the evaluation result

  --- create a clone with its own identity.
  --
  -- creates a clone of this Cell with its own identity by prepending a `parent`
  -- Tag (and cloning all child expressions recursively).
  --
  -- @function clone
  -- @tparam Tag parent
  -- @treturn AST

  --- stringify this AST Node.
  --
  -- Should return the exact string this node was parsed from (if it was parsed).
  --
  -- @function stringify
  -- @treturn string the exact string this Node was parsed from

import Cell from require 'alv.cell'
import Constant from require 'alv.result.const'
import Dummy from require 'alv.dummy'
import Tag from require 'alv.tag'

{
  :Cell
  :Constant
  :Dummy
  :Tag
}
