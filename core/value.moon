-- ALV Value types
import Op, Action, FnDef from require 'core.base'

local Scope
load_ = ->
  import Scope from require 'core.scope'

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
--
-- ResultNodes form a tree that controls execution order and message passing
-- between Ops.
class ResultNode
  -- params: table with optional keys op, value, children
  new: (params={}) =>
    @op = params.op
    @value = params.value
    @children = params.children or {}

  -- unwrap value and assert that neither @op nor @children were set
  value_only: (msg) =>
    assert not @op and #@children == 0, msg or "pure expression expected"
    @value

  update: (dt) =>
    for child in *@children
      child\update dt
    @op\update dt if @op

  __tostring: =>
    buf = "<result=#{@value}"
    buf ..= " #{@op}" if @op
    buf ..= " (#{#@children} children)" if #@children > 0
    buf ..= ">"
    buf

local Const, Stream

-- ALV Type wrapper
class Value
  -- @type      - type name.
  --              builtin types: * literals: sym, num, bool
  --                             * scope, opdef, fndef, builtin
  -- @value     - Lua value - access through :unwrap()
  new: (@type, @value) =>

  -- asserts value-constness
  -- returns self (for chaining)
  const: => error 'not a constant'

  -- unwrap to the Lua type
  -- asserts @type == type, msg if given
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    @value

-- static
  __tostring: =>
    value = if 'table' == (type @value) and rawget @value, '__base' then @value.__name else @value
    "<#{@@__name} #{@type}: #{value}>"
  __eq: (other) => other.type == @type and other.value == @value
  __inherited: (cls) =>
    cls.__base.__tostring = @__tostring
    cls.__base.__eq = @__eq

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
          return Const 'scope', Scope.from_table val
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Const typ, val

class Stream extends Value
  new: (@type, @value=nil) =>

  set: (@value) =>
    -- set dirty flag (?)

class Const extends Value
  new: (type, value, @raw) =>
    super type, value

-- Value interface
  const: => @

-- AST interface
  eval: (scope) =>
    value = switch @type
      when 'num', 'str'
        @
      when 'sym'
        assert (scope\get @value), "undefined reference to symbol '#{@value}'"
      else
        error "cannot evaluate #{@}"

    ResultNode :value

  quote: => @

  stringify: => @raw

  clone: (prefix) => @
  -- in case of doubt:
  -- clone: (prefix) => Const @type, @value, @raw

-- static
  unescape = (str) -> str\gsub '\\([\'"\\])', '%1'

  @parse: (type, sep) =>
    switch type
      when 'num' then (match) -> @ 'num', (tonumber match), match
      when 'sym' then (match) -> @ 'sym', match, match
      when 'str' then (match) -> @ 'str', (unescape match), sep .. match .. sep

  @num: (num) -> Const 'num', num, tostring num
  @str: (str) -> Const 'str', str, "'#{str}'"
  @sym: (sym) -> Const 'sym', sym, sym
  @bool: (bool) -> Const 'bool', bool, tostring bool

{
  :ResultNode
  :Value
  :Stream, :Const
  :load_
}
