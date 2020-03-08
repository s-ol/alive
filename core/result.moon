----
-- Result of evaluating an expression.
--
-- `Result`s form a tree that controls execution order and message passing
-- between `Op`s.
--
-- @classmod Result
import base from require 'core.cycle'

class Result
--- members
-- @section members

  --- return whether this Result's value is const.
  is_const: => not next @side_inputs

  --- assert value-constness and returns the value.
  -- @tparam[opt] string msg the error message to throw
  const: (msg) =>
    assert not (next @side_inputs), msg or "eval-time const expected"
    @value

  --- assert this result has a value, returns its type.
  type: =>
    assert @value, "Result with value expected"
    @value.type

  --- create a copy of this result with value-copy semantics.
  -- the copy has the same @value and @side_inputs, but will not update
  -- anything on \tick.
  make_ref: =>
    with Result value: @value
      .side_inputs = @side_inputs

  --- tick all IO instances that are effecting this (sub)tree.
  -- should be called once per frame on the root, right before tick.
  tick_io: =>
    for stream, input in pairs @side_inputs
      if input.__class == base.IOInput
        io = input!
        io\tick!

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
      for stream in @op\all_inputs!
        if stream\dirty!
          self_dirty = true
          break

      L\trace "#{@op} is #{if self_dirty then 'dirty' else 'clean'}"
      return unless self_dirty

      @op\tick!

  __tostring: =>
    buf = "<result=#{@value}"
    buf ..= " #{@op}" if @op
    buf ..= " (#{#@children} children)" if #@children > 0
    buf ..= ">"
    buf

  --- the `Value` result
  --
  -- @tfield ?Value value

  --- an Op
  --
  -- @tfield ?Op op

  --- list of child `Result`s from subexpressions
  --
  -- @tfield {}|{Result,...} children

  --- cached mapping of all `Value`/`Input` pairs affecting this Result.
  --
  -- This is the union of all `children`s `side_inputs` and all `Input`s from
  -- `op` that are not the `value` of any child.
  --
  -- @tfield {[Value]=Input,...} side_inputs

--- static functions
-- @section static

  --- create a new Result.
  -- @classmethod
  -- @param params table with optional keys op, value, children. default: {}
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


{
  :Result
}
