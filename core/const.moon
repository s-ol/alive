import Op, Action, FnDef from require 'core.base'

local Scope
load_ = ->
  import Scope from require 'core.scope'

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

class Ref
  new: (@original) =>

  get: (...) => @original\get ...
  getc: (...) => @original\get ...

  destroy: =>
  update: =>

class Const
  types = {
    sym: true
    str: true
    num: true
    bool: true
    scope: true
    op: true
    opdef: true
    fndef: true
    builtin: true
  }

  new: (@type, @value, @raw) =>
    assert types[@type], "invalid Const type: #{@type}"

-- Value interface
  get: (type) =>
    assert not type or type == @type, "#{@} is not a #{type}"
    @value

  getc: (type) =>
    assert not type or type == @type, "#{@} is not a #{type}"
    @value

  update: (dt) =>
    switch @type
      when 'op'
        @value\update dt

-- AST interface
  eval: (scope) =>
    switch @type
      when 'num', 'str'
        @
      when 'sym'
        assert (scope\get @value), "undefined reference to symbol '#{@value}'"
      else
        error "cannot evaluate #{@}"

  quote: => @

  stringify: => @raw

  clone: (prefix) => @
  -- in case of doubt:
  -- clone: (prefix) => Const @type, @value, @raw

-- static
  __tostring: =>
    value = if @type == 'opdef' or @type == 'builtin' then @value.__name else @value
    "<#{@type}: #{value}>"

  __eq: (other) =>
    other.type == @type and other.value == @value

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
  @empty: -> Const 'str', '', "''"

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
            when Op then 'op'
            when Scope then 'scope'
            when FnDef then 'fndef'
            when Const
              return val
            else
              error "#{name}: cannot wrap '#{val.__class.__name}' instance"
        else
          -- plain table
          return Const 'scope', Scope.from_table val
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Const typ, val

  @wrap_ref: (val) ->
    if base = rawget val, '__base'
      -- a class
      error "#{name}: cannot wrap_ref class '#{val.__name}'"
    elseif val.__class
      -- an instance
      switch ancestor val.__class
        when Op then Ref val
        when Const then val
        else
          error "#{name}: cannot wrap_ref '#{val.__class.__name}' instance"
    else
      error "#{name}: cannot wrap_ref Lua type '#{type val}'"

:Const, :load_
