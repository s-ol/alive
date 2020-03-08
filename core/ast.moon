----
-- AST Node Interface.
--
-- implemented by `Value` and `Cell`.
--
-- @classmod AST


--- members
-- @section members

  --- evaluate this AST Node.
  --
  -- Evaluate this node and return a `Result`.
  --
  -- @class function
  -- @name eval
  -- @tparam Scope scope the scope to evaluate in
  -- @treturn Result the evaluation result

  --- quote this AST Node, preserving its identity.
  --
  --- Returns a mutable copy of this Node that shares its identity.
  --
  -- @class function
  -- @name quote
  -- @treturn AST

  --- create a clone with its own identity.
  --
  -- creates a clone of this Cell with its own identity by prepending a `parent`
  -- Tag (and cloning all child expressions recursively).
  --
  -- @class function
  -- @name clone
  -- @tparam Tag parent
  -- @treturn AST

  --- stringify this AST Node.
  --
  -- Should return the exact string this node was parsed from (if it was parsed).
  --
  -- @class function
  -- @name stringify
  -- @treturn string the exact string this Node was parsed from
