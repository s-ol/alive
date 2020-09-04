----
-- RTNode of evaluating an expression.
--
-- `RTNode`s form a tree that controls execution order and message
-- between `Op`s.
--
-- @classmod RTNode
import Error from require 'alv.error'

class RTNode
--- members
-- @section members

  --- return whether this RTNode's result is const.
  is_const: => not next @side_inputs

  --- assert result-constness and return the result.
  -- @tparam[opt] string msg the error message to throw
  -- @treturn any
  const: (msg) =>
    assert not (next @side_inputs), msg or "eval-time const expected"
    @result

  --- assert this result has a result, return its type.
  -- @treturn string
  type: =>
    assert @result, "RTNode with result expected"
    @result.type

  --- assert this result has a result, returns its metatype.
  -- @treturn string `"result"` or `"event"`
  metatype: =>
    assert @result, "RTNode with result expected"
    @result.metatype

  --- create a copy of this result with result-copy semantics.
  --
  -- the copy has the same @result and @side_inputs, but will not (doubly)update
  -- anything on `tick` or `poll`.
  make_ref: =>
    RTNode result: @result, side_inputs: @side_inputs

  --- poll all IO Ops effecting this (sub)tree for changes.
  --
  -- should be called once per frame on the root, right before tick.
  --
  -- @treturn ?boolean whether any IO Op marked itself dirty.
  poll_io: =>
    dirty = false

    for op in *@io_ops
      dirty = op\poll! or dirty

    dirty

  --- in depth-first order, tick all Ops which have dirty Inputs.
  --
  -- short-circuits if there are no dirty Inputs in the entire subtree
  tick: =>
    if #@io_ops == 0
      any_dirty = false
      for result, input in pairs @side_inputs
        if input\dirty!
          any_dirty = true
          break

      -- early-out if no Inputs are dirty in this whole subtree
      return unless any_dirty

    for child in *@children
      child\tick!

    if @op
      -- we have to check self_dirty here, because Inputs from children may
      -- have become dirty due to \tick
      self_dirty = false
      for input in @op\all_inputs!
        if input\dirty!
          self_dirty = true

      return unless self_dirty

      Error.wrap "ticking #{op}", @op\tick

  __tostring: =>
    buf = "<RT=#{@result}"
    buf ..= " #{@op}" if @op
    buf ..= " (#{#@children} children)" if #@children > 0
    buf ..= ">"
    buf

  --- the `Result` result.
  -- @tfield ?Result result

  --- an Op.
  -- @tfield ?Op op

  --- list of child `RTNode`s from subexpressions.
  -- @tfield {RTNode,...} children

  --- cached list of all IO Ops inside this RTNode and children.
  -- @tfield {Op,...} io_ops

  --- cached mapping of all `Result`/`Input` pairs affecting this RTNode.
  --
  -- This is the union of all `children`s `side_inputs` and all `Input`s from
  -- `op` that are not the `result` of any child.
  --
  -- @tfield {[Result]=Input,...} side_inputs

--- static functions
-- @section static

  --- create a new RTNode.
  -- @classmethod
  -- @param params table with optional keys op, result, children. default: {}
  new: (params={}) =>
    @result = params.result
    @op = params.op
    @children = params.children or {}
    @io_ops = params.io_ops or {}

    if params.side_inputs
      @side_inputs = params.side_inputs
      return

    @side_inputs = {}
    is_child = {}

    for child in *@children
      -- collect child side_inputs
      for result, input in pairs child.side_inputs
        @side_inputs[result] = input

      -- collect child io_ops
      for op in *child.io_ops
        table.insert @io_ops, op

      if child.result
        is_child[child.result] = true

    if @op
      if @op.poll
        table.insert @io_ops, @op

      -- find inputs outside this tree
      for i in @op\all_inputs!
        if i.mode == 'hot' and not is_child[i.result]
          @side_inputs[i.result] = i

    -- "freeze" ~-streams if there are no IO Ops around
    return unless @result and @result.metatype == '~'
    return if #@io_ops > 0

    all_const = true
    for result, input in pairs @side_inputs
      if result.metatype != '='
        all_const = false
        break
    return unless all_const

    @result = @result.type\mk_const @result\unwrap!

{
  :RTNode
}
