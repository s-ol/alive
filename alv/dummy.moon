----
-- Dummy AST Node.
--
-- Implements the `AST` interface.
--
-- @classmod Dummy
import RTNode from require 'alv.rtnode'
import Constant from require 'alv.result.const'
import Error from require 'alv.error'

class Dummy
--- members
-- @section members

  --- the contained node.
  --
  -- @tfield RTNode node

--- AST interface
--
-- `Dummy` implements the `AST` interface.
-- @section ast

  --- evaluate this Dummy.
  --
  -- returns `node`
  -- @treturn RTNode `node`
  eval: => @node

  --- create a clone with its own identity.
  --
  -- returns a ref to `node`.
  --
  -- @tparam Tag parent
  -- @treturn Cell
  clone: => @

  --- stringify this Dummy.
  --
  -- throws an error, `Dummy` nodes cannot be stringified.
  stringify: => error Error, 'implementation', "cannot stringify Dummy"

--- static functions
-- @section static

  --- construct a new Dummy from a `RTNode`.
  --
  -- @classmethod
  -- @tparam RTNode node
  new: (@node) =>

  --- construct a new Dummy from a plain value.
  --
  -- @tparam Type type
  -- @tparam any value
  -- @tparam string raw string
  @literal: (...) -> @@ RTNode result: Constant ...

{
  :Dummy
}
