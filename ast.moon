import Const from require 'base'
unpack or= table.unpack

unescape = (str) ->
  str = str\gsub '\\"', '"'
  str = str\gsub "\\'", "'"
  str = str\gsub "\\\\", "\\"
  str

class Atom
  type: 'Atom'

  new: (@raw, @style='', value) =>
    @value = Const value

  _walk: => coroutine.yield @type, @

  stringify: =>
    switch @style
      when ''
        @raw
      when '"'
        "\"#{@raw}\""
      when "'"
        "'#{@raw}'"
      else
        error "unknown atom style: '#{@style}'"

  @make_num: (match, ...) -> Atom match, '', tonumber match
  @make_sym: (match) -> Atom match, '', match
  @make_strd: (match) -> Atom match, '"', unescape match
  @make_strq: (match) -> Atom match, "'", unescape match

  __tostring: => @stringify!

class Xpr
  type: 'Xpr'
  
  new: (parts, @style='(', tag) =>
    @white = {}
    @white[0] = parts[1]

    for i = 2,#parts,2
      @[i/2] = parts[i]
      @white[i/2] = parts[i+1]

    if tag
      @tag = tag.value\getc!

  _walk: (dir, yield_self=true) =>
    coroutine.yield @type, @ if yield_self and dir == 'outin'

    for frag in *@
      frag\_walk dir

    coroutine.yield @type, @ if yield_self and dir == 'inout'


  head: => @[1].value
  tail: => unpack [p.value for p in *@[2,]]

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

  make_sexpr: (tag, parts) ->
    if parts
      Xpr parts, '(', tag
    else
      Xpr tag, '('

  make_nexpr: (parts) -> Xpr parts, 'naked'

  __tostring: =>
    if @tag
      "<Xpr[#{@tag}] #{@value}>"
    else
      "<Xpr #{@value}>"

{
  :Atom
  :Xpr
}
