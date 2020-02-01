import Const from require 'base'
import Scope from require 'scope'
unpack or= table.unpack

hash = (tbl) ->
  mt = getmetatable tbl
  setmetatable tbl, nil
  str = tostring tbl
  setmetatable tbl, mt

  '#' .. str\sub 10

class ASTNode
  -- first pass (outin):
  -- * expand macros
  -- * define scoped values
  -- * evaluate references
  expand: (scope) =>

  -- second pass (inout):
  -- * setup OPs (spawn/patch)
  link: =>

class Atom
  type: 'Atom'

  new: (@raw, @atom_type) =>

  unescape = (str) ->
    str = str\gsub '\\"', '"'
    str = str\gsub "\\'", "'"
    str = str\gsub "\\\\", "\\"
    str
  expand: (scope) =>
    @value = switch @atom_type
      when 'num'
        Const 'num', tonumber @raw
      when 'strq', 'strd'
        Const 'str', unescape @raw
      when 'sym'
        assert (scope\get @raw), "undefined reference to symbol '#{@raw}'"
      else
        error "unknown atom type: '#{@atom_type}'"

  link: =>

  _walk: => coroutine.yield @type, @

  stringify: =>
    switch @atom_type
      when 'sym', 'num'
        @raw
      when 'strq'
        "'#{@raw}'"
      when 'strd'
        "\"#{@raw}\""
      else
        error "unknown atom type: '#{@atom_type}'"

  @make_num:  (match) -> Atom match, 'num'
  @make_sym:  (match) -> Atom match, 'sym'
  @make_strd: (match) -> Atom match, 'strd'
  @make_strq: (match) -> Atom match, 'strq'

  __tostring: =>
    "<Atom#{hash @} #{@stringify!}>"

class Xpr
  type: 'Xpr'

  -- either:
  -- * style, tag, parts
  -- * style, parts
  new: (@style, tag, parts) =>
    if not parts
      parts = tag
      tag = nil

    @tag = tag

    @white = {}
    @white[0] = parts[1]

    for i = 2,#parts,2
      @[i/2] = parts[i]
      @white[i/2] = parts[i+1]

  expand: (scope) =>
    scope = Scope @, scope
    for child in *@
      child\expand scope

  link: =>
    head = @head!

  head: => @[1].value
  tail: => unpack [p.value for p in *@[2,]]

  _walk: (dir, yield_self=true) =>
    coroutine.yield @type, @ if yield_self and dir == 'outin'

    for frag in *@
      frag\_walk dir

    coroutine.yield @type, @ if yield_self and dir == 'inout'

  walk: (dir, yield_self=true) =>
    assert dir == 'inout' or dir == 'outin', "dir has to be either inout or outin"
    coroutine.wrap -> @_walk dir, yield_self

  stringify: =>
    buf = ''
    buf ..= @white[0]
    for i, frag in ipairs @
      buf ..= frag\stringify!
      buf ..= @white[i]

    switch @style
      when 'naked'
        buf
      when '('
        tag = if @tag then "[#{@tag}]" else ''
        '(' .. tag .. buf .. ')'
      else
        error "unknown sexpr style: '#{@style}'"

  make_sexpr: (...) -> Xpr '(', ...
  make_nexpr: (...) -> Xpr 'naked', ...

  __tostring: =>
    if @tag
      "<Xpr[#{@tag}] #{@value}>"
    else
      "<Xpr #{@value}>"

{
  :Atom
  :Xpr
}
