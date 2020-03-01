-- ALV Value types
local Scope, Registry, Op, Action, FnDef
load_ = ->
  import Scope from require 'core.scope'
  import Registry from require 'core.registry'
  import Op, Action, FnDef from require 'core.base'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

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
      for d in pairs child.side_inputs
        @side_inputs[d] = true
      if child.value
        is_child[child.value] = true

    if @op
      for input in @op\all_inputs!
        continue if is_child[input]
        @side_inputs[input] = true

  is_const: => not next @side_inputs

  -- asserts value-constness and returns the value
  const: (msg) =>
    assert not (next @side_inputs), msg or "eval-time const expected"
    @value

  -- create a value-copy of this result that has the same impulses but without
  -- affecting the original's update logic
  make_ref: =>
    with Result value: @value
      .side_inputs = @side_inputs

  -- in depth-first order, tick all Ops who have dirty Stream inputs or impulses
  --
  -- short-circuits if there are no dirty Streams in the entire subtree
  tick: =>
    any_dirty = false
    for input in pairs @side_inputs
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

-- ALV Type wrapper
class Value
  -- @type      - type name.
  --              builtin types: * literals: sym, num, bool
  --                             * scope, opdef, fndef, builtin
  -- @value     - Lua value - access through :unwrap()
  new: (@type, @value, @raw) =>
    @updated = 0

  dirty: => @updated == Registry.active!.tick

  set: (@value) => @updated = Registry.active!.tick

  -- unwrap to the Lua type
  -- asserts @type == type, msg if given
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    @value

-- AST interface
  eval: (scope) =>
    switch @type
      when 'num', 'str'
        Result value: @
      when 'sym'
        assert (scope\get @value), "undefined reference to symbol '#{@value}'"
      else
        error "cannot evaluate #{@}"

  quote: => @

  stringify: => assert @raw, "stringifying Value that wasn't parsed"

  clone: (prefix) => @
  -- in case of doubt:
  -- clone: (prefix) => Value @type, @value, @raw

-- static
  __tostring: =>
    value = if 'table' == (type @value) and rawget @value, '__base' then @value.__name else @value
    "<#{@@__name} #{@type}: #{value}>"
  __call: (...) => @unwrap ...
  __eq: (other) => other.type == @type and other.value == @value

  -- wrap a Lua type
  @wrap: (val, name='(unknown)') ->
    typ = switch type val
      when 'number' then 'num'
      when 'string' then 'str'
      when 'table'
        if base = rawget val, '__base'
          -- a class
          switch ancestor val
            when Op then 'opdef'
            when Action then 'builtin'
            else
              error "#{name}: cannot wrap class '#{val.__name}'"
        elseif val.__class
          -- an instance
          switch ancestor val.__class
            when Scope then 'scope'
            when FnDef then 'fndef'
            when Value
              return val
            else
              error "#{name}: cannot wrap '#{val.__class.__name}' instance"
        else
          -- plain table
          return Value 'scope', Scope.from_table val
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Value typ, val

  unescape = (str) -> str\gsub '\\([\'"\\])', '%1'
  @parse: (type, sep) =>
    switch type
      when 'num' then (match) -> @ 'num', (tonumber match), match
      when 'sym' then (match) -> @ 'sym', match, match
      when 'str' then (match) -> @ 'str', (unescape match), sep .. match .. sep

  @num: (num) -> Value 'num', num, tostring num
  @str: (str) -> Value 'str', str, "'#{str}'"
  @sym: (sym) -> Value 'sym', sym, sym
  @bool: (bool) -> Value 'bool', bool, tostring bool

{
  :Result
  :Value
  :load_
}
