import Const, Forward from require 'base'
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
  -- * expand macros (mutate scopes)
  -- * resolve symbols
  expand: (scope) =>

  -- second pass (inout):
  -- * setup expressions (spawn/patch)
  patch: (map) =>

  -- runtime pass (inout)
  update: (dt) =>

  -- return a copy
  clone: (tag_prefix) =>

class Atom extends ASTNode
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

    @value

  expand_quoted: =>
    switch @atom_type
      when 'num'
        Const 'num', tonumber @raw
      when 'strq', 'strd'
        Const 'str', unescape @raw
      when 'sym'
        Const 'sym', @raw
      else
        error "unknown atom type: '#{@atom_type}'"

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

  -- atoms are immutable
  clone: (tag_prefix) => Atom @raw, @atom_type

  @make_num:  (match) -> Atom match, 'num'
  @make_sym:  (match) -> Atom match, 'sym'
  @make_strd: (match) -> Atom match, 'strd'
  @make_strq: (match) -> Atom match, 'strq'

  __tostring: =>
    "<Atom#{hash @} #{@stringify!}>"

class Xpr extends ASTNode
  type: 'Xpr'

  -- either:
  -- * style, tag, parts, white
  -- * style, tag, parts
  -- * style, parts
  new: (@style, tag, parts, white) =>
    if white
      for i, part in ipairs parts
        @[i] = part
    else
      if not parts
        parts = tag
        tag = nil

      @white = {}
      @white[0] = parts[1]

      for i = 2,#parts,2
        @[i/2] = parts[i]
        @white[i/2] = parts[i+1]

    @tag = tag

  expand: (scope) =>
    @[1]\expand scope
    head = @head!

    @scope = Scope @, scope

    switch head.type
      when 'macrodef'
        Macrodef = head\getc!
        @macro = Macrodef @
        @value = @macro\expand scope
      else
        for child in *@[2,]
          child\expand @scope

    @value or Forward @

  patch: (map) =>
    L\trace "patching #{@deep_tostring!}"
    prev = map[@tag]

    if @macro
      -- forward for macros
      if prev and prev.macro then prev.macro\destroy!
      elseif prev and prev.value then prev.value\destroy!
      @macro\patch map
      return

    compatible = prev and
                 prev.value and
                 prev\head! == head

    for child in *@
      L\push child\patch, map
    head = @head!

    if compatible
      -- continued existance
      @value = prev.value
      @value\setup @tail!
      L\trace "continued with", @tail!
    else
      -- destroy + recreate
      prev.value\destroy! if prev and prev.value
      @value = head\getc!\spawn @tail!
      L\trace "recreated with", @tail!

  update: (dt) =>
    if @macro
      @macro\update dt
      return

    L\trace "updating #{@}"
    for child in *@[2,]
      L\push child\update, dt

    @value\update dt

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

  clone: (tag_prefix) =>
    parts = [part\clone tag_prefix for part in *@]
    Xpr @style, "#{tag_prefix}.#{@tag}", parts, @white

  make_sexpr: (...) -> Xpr '(', ...
  make_nexpr: (...) -> Xpr 'naked', ...

  deep_tostring: =>
    buf = "("
    buf ..= "[#{@tag}]" if @tag
    buf ..= "#{@[1].raw}"
    buf ..= " #{table.concat [tostring child for child in *@], ' '}" if #@ > 1
    buf ..= ")"
    buf

  __tostring: =>
    if @style == 'naked'
      return 'ROOT'

    buf = "("
    buf ..= "[#{@tag}]" if @tag
    buf ..= "#{@[1].raw}"
    buf ..= " ..." if #@ > 1
    buf ..= ")"
    buf

{
  :Atom
  :Xpr
}
