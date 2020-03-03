import base from require 'core.cycle'

-- Result of evaluating an expression
-- carries (all optional):
-- - a Value
-- - an Op (to update)
-- - children (results of subexpressions that were evaluated)
-- - cached list of all Dispatchers affecting all Ops in the subtree
--
-- Results form a tree that controls execution order and message passing
-- between Ops.
class Result
  -- params: table with optional keys op, value, children
  new: (params={}) =>
    @value = params.value
    @op = params.op
    @children = params.children or {}

    @side_inputs, is_child = {}, {}
    for child in *@children
      for s, d in pairs child.side_inputs
        @side_inputs[s] = d
      if child.value
        is_child[child.value] = true

    if @op
      for input in @op\all_inputs!
        if input.impure or not is_child[input.stream]
          @side_inputs[input.stream] = input

  is_const: => not next @side_inputs

  -- asserts value-constness and returns the value
  const: (msg) =>
    assert not (next @side_inputs), msg or "eval-time const expected"
    @value

  -- asserts a value exists and returns its type
  type: =>
    assert @value, "Result with value expected"
    @value.type

  -- create a value-copy of this result that has the same impulses but without
  -- affecting the original's update logic
  make_ref: =>
    with Result value: @value
      .side_inputs = @side_inputs

  -- tick all IO instances that are effecting this (sub) tree
  -- should be called once per frame on the root, right before tick
  tick_io: =>
    for stream, input in pairs @side_inputs
      if input.__class == base.IOInput
        io = input!
        io\tick!

  -- in depth-first order, tick all Ops who have dirty Stream inputs or impulses
  --
  -- short-circuits if there are no dirty Streams in the entire subtree
  tick: =>
    any_dirty = false
    for stream, input in pairs @side_inputs
      if input\dirty!
        any_dirty = true
        break

    -- early-out if no streams are dirty in this whole subtree
    return unless any_dirty

    for child in *@children
      child\tick!

    if @op
      -- we have to check self_dirty here, because streams from child
      -- expressions might have changed
      self_dirty = false
      for stream in @op\all_inputs!
        if stream\dirty!
          self_dirty = true
          break

      L\trace "#{@op} is #{if self_dirty then 'dirty' else 'clean'}"
      return unless self_dirty

      @op\tick!

-- static
  __tostring: =>
    buf = "<result=#{@value}"
    buf ..= " #{@op}" if @op
    buf ..= " (#{#@children} children)" if #@children > 0
    buf ..= ">"
    buf

{
  :Result
}
