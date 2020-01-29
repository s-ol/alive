class Atom
  new: (@raw, @style='', @value) =>

  _walk_sexpr: =>

  stringify: =>
    switch @style
      when ''
        @raw
      when '"'
        "\"#{@raw}\""
      else
        error!

  @make_num: (match) -> Atom match, '', tonumber match
  @make_sym: (match) -> Atom match, '', match
  @make_str: (match) -> Atom match, '"', match

class Xpr
  new: (parts, @style='(', tag) =>
    @white = {}
    @white[0] = parts[1]

    for i = 2,#parts,2
      @[i/2] = parts[i]
      @white[i/2] = parts[i+1]

    if tag
      @tag = tag.value

  _walk_sexpr: =>
    if @style == '('
      coroutine.yield @

    for frag in *@
      frag\_walk_sexpr!

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
      else
        tag = if @tag then "[#{@tag}]" else ''
        '(' .. tag .. buf .. ')'

  make_sexpr: (tag, parts) ->
    if parts
      Xpr parts, '(', tag
    else
      Xpr tag, '('

  make_nexpr: (parts) -> Xpr parts, 'naked'

{
  :Atom
  :Xpr
}
