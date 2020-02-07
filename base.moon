import Scope from require 'scope'

unpack or= table.unpack

ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

class Op
-- common
  new: (...) =>
    @setup ...

  get: => @value
  getc: =>
    L\warn "stream #{@} cast to constant"
    @value

-- interface
  update: (dt) =>

  destroy: =>

-- static
  __tostring: => "<op: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

  spawn: (Opdef, ...) ->
    Opdef ...

class Action
-- common
  new: (head, @tag, @registry) =>
    @patch head

  register: =>
    @tag = @registry\register @, @tag

-- interface
  -- * eval args
  -- * perform scope effects
  -- * patch nested exprs
  -- * return runtime-tree value
  eval: (scope, tail) => error "not implemented"

  -- free resources
  destroy: =>

  -- update this instance for :eavl() with new head
  -- if :patch() returns false, this instance is :destroy'ed and recreated instead
  -- must *not* return false when called after :new()
  -- only considered if Action types match
  patch: (head) =>
    if head == @head
      true

    @head = head

-- static
  @get_or_create: (ActionType, head, tag, registry) ->
    last = tag and registry\find tag
    compatible = last and
                 last.__class == ActionType and
                 last\patch head

    if not compatible
      last\destroy! if last
      compatible = ActionType head, tag, registry

    with compatible
      \register!

  __tostring: => "<action: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

class Const
  types = {
    sym: true
    scope: true
    str: true
    num: true
    op: true
    opdef: true
    builtin: true
  }

-- Value interface
  new: (@type, @value, @raw) =>
    assert types[@type], "invalid Const type: #{@type}"

  get: (type) =>
    assert not type or type == @type, "#{@} is not a #{type}"
    @value

  getc: (type) =>
    assert not type or type == @type, "#{@} is not a #{type}"
    @value

-- AST interface
  eval: (scope) =>
    switch @type
      when 'num', 'str'
        @
      when 'sym'
        assert (scope\get @value), "undefined reference to symbol '#{@raw}'"
      else
        error "cannot evaluate #{@}"

  quote: => @

  stringify: => @raw

-- static
  __tostring: =>
    value = if @type\match 'def$' then @value.__name else @value
    "<#{@type}: #{value}>"

  __eq: (other) =>
    other.type == @type and other.value == @value

  unescape = (str) ->
    str = str\gsub '\\"', '"'
    str = str\gsub "\\'", "'"
    str = str\gsub "\\\\", "\\"
    str

  @parse: (type, sep) =>
    switch type
      when 'num' then (match) -> @ 'num', (tonumber match), match
      when 'sym' then (match) -> @ 'sym', match, match
      when 'str' then (match) -> @ 'str', (unescape match), sep .. match .. sep

  @num: (num) -> Const 'num', num
  @str: (str) -> Const 'str', str
  @sym: (sym) -> Const 'sym', sym

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

local builtin
class Cell
-- common
  new: (@tag, @children, @white) =>
    builtin or= require 'lib.builtin'

  head: => @children[1]
  tail: => [c for c in *@children[2,]]

-- AST interface
  eval: (scope, registry) =>
    head = @head!\eval scope, registry
    Action = switch head.type
      when 'opdef'
        -- scope\get 'op-invoke'
        builtin['op-invoke']
      when 'fndef'
        -- scope\get 'fn-invoke'
        builtin['fn-invoke']
      when 'builtin'
        head\getc!
      else
        error "cannot evaluate expr with head #{head}"

    action = Action\get_or_create head, tag, registry
    action\eval scope, @tail!

  quote: (scope, registry) =>
    tag = registry\register @, @tag
    children = [child\quote scope, registry for child in *@children]
    Cell tag, children, @white, @style

  stringify: (inner=false) =>
    buf = ''
    buf ..= @white[0]
    for i, child in ipairs @children
      buf ..= child\stringify!
      buf ..= @white[i]

    return buf if inner

    tag = if @tag then "[#{@tag\stringify!}]" else ''
    '(' .. tag .. buf .. ')'

-- static
  parse_args = (tag, parts) ->
    if not parts
      parts, tag = tag, nil

    children, white = {}, { [0]: parts[1] }

    for i = 2,#parts,2
      children[i/2] = parts[i]
      white[i/2] = parts[i+1]

    tag, children, white
  @parse: (...) =>
    tag, children, white = parse_args ...
    @ tag, children, white

class RootCell extends Cell
  head: => Const.sym 'do'
  tail: => @children

  stringify: =>
    super\stringify true

{
  :Op
  :Const
  :Action
  :Cell, :RootCell
}
