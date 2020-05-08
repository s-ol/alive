----
-- RTNode of evaluating an expression.
--
-- `RTNode`s form a tree that controls execution order and message
-- between `Op`s.
--
-- @classmod RTNode
class RTNode
--- members
-- @section members

  --- return whether this RTNode's value is const.
  is_const: => not next @side_inputs

  --- assert value-constness and return the value.
  -- @tparam[opt] string msg the error message to throw
  -- @treturn any
  const: (msg) =>
    assert not (next @side_inputs), msg or "eval-time const expected"
    @value

  --- assert this result has a value, return its type.
  -- @treturn string
  type: =>
    assert @value, "RTNode with value expected"
    @value.type

  --- assert this result has a value, returns its metatype.
  -- @treturn string `"value"` or `"event"`
  metatype: =>
    assert @value, "RTNode with value expected"
    @value.metatype

  --- create a copy of this result with value-copy semantics.
  -- the copy has the same @value and @side_inputs, but will not update
  -- anything on \tick.
  make_ref: =>
    with RTNode value: @value
      .side_inputs = @side_inputs

  --- poll all IOStream instances that are effecting this (sub)tree.
  -- should be called once per frame on the root, right before tick.
  poll_io: =>
    for stream, input in pairs @side_inputs
      stream\poll! if input.io

  --- in depth-first order, tick all Ops which have dirty Inputs.
  --
  -- short-circuits if there are no dirty Inputs in the entire subtree
  tick: =>
    any_dirty = false
    for stream, input in pairs @side_inputs
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

      @op\tick!

  __tostring: =>
    buf = "<RT=#{@value}"
    buf ..= " #{@op}" if @op
    buf ..= " (#{#@children} children)" if #@children > 0
    buf ..= ">"
    buf

  --- the `Stream` result
  --
  -- @tfield ?Stream value

  --- an Op
  --
  -- @tfield ?Op op

  --- list of child `RTNode`s from subexpressions
  --
  -- @tfield {}|{RTNode,...} children

  --- cached mapping of all `Stream`/`Input` pairs affecting this RTNode.
  --
  -- This is the union of all `children`s `side_inputs` and all `Input`s from
  -- `op` that are not the `value` of any child.
  --
  -- @tfield {[Stream]=Input,...} side_inputs

--- static functions
-- @section static

  --- create a new RTNode.
  -- @classmethod
  -- @param params table with optional keys op, value, children. default: {}
  new: (params={}) =>
    @value = params.value
    @op = params.op
    @children = params.children or {}

    @side_inputs, is_child = {}, {}
    for child in *@children
      for stream, input in pairs child.side_inputs
        @side_inputs[stream] = input
      if child.value
        is_child[child.value] = true

    if @op
      for input in @op\all_inputs!
        if input.io or not is_child[input.stream]
          @side_inputs[input.stream] = input

{
  :RTNode
}
