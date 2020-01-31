import Const from require 'base'
unpack or= table.unpack

unescape = (str) ->
  str = str\gsub '\\"', '"'
  str = str\gsub "\\'", "'"
  str = str\gsub "\\\\", "\\"
  str

class Atom
  new: (@raw, @style='', value) =>
    @value = Const value

  _walk_sexpr: =>

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
  new: (parts, @style='(', tag) =>
    @white = {}
    @white[0] = parts[1]

    for i = 2,#parts,2
      @[i/2] = parts[i]
      @white[i/2] = parts[i+1]

    if tag
      @tag = tag.value\getc!

  _walk_sexpr: =>
    -- depth first
    for frag in *@
      frag\_walk_sexpr!

    if @style == '('
      coroutine.yield @

  head: => @[1].value
  tail: => unpack [p.value for p in *@[2,]]

  walk_sexpr: =>
    coroutine.wrap -> @_walk_sexpr!

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
