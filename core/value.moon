import Result from require 'core.result'
import scope, base, registry from require 'core.cycle'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

-- ALV Type wrapper
class Value
  -- @type      - type name.
  --              builtin types: * literals: sym, num, bool
  --                             * scope, opdef, fndef, builtin
  -- @value     - Lua value - access through :unwrap()
  new: (@type, @value, @raw) =>
    @updated = nil

  dirty: => @updated == registry.Registry.active!.tick

  set: (@value) => @updated = registry.Registry.active!.tick

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
        if rawget val, '__base'
          -- a class
          switch ancestor val
            when base.Op then 'opdef'
            when base.Action then 'builtin'
            else
              error "#{name}: cannot wrap class '#{val.__name}'"
        elseif val.__class
          -- an instance
          switch ancestor val.__class
            when scope.Scope then 'scope'
            when base.FnDef then 'fndef'
            when Value
              return val
            else
              error "#{name}: cannot wrap '#{val.__class.__name}' instance"
        else
          -- plain table
          return Value 'scope', scope.Scope.from_table val
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
  :Value
  :load_
}
