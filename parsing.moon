lpeg = require 'lpeg'

class Atom
  new: (@raw, @style='', @value) =>

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
  new: (parts, @style='(') =>
    @white = {}
    @white[0] = parts[1]

    for i = 2,#parts,2
      @[i/2] = parts[i]
      @white[i/2] = parts[i+1]

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
        '(' .. buf .. ')'

  make_sexpr: (parts) -> Xpr parts, '('
  make_nexpr: (parts) -> Xpr parts, 'naked'

space = (lpeg.S ' \t\r\n') ^ 1 / 1
mspace = (lpeg.S ' \t\r\n') ^ 0 / 1

sym = ((lpeg.R 'az', 'AZ') + (lpeg.S '-_+*')) ^ 1 / Atom.make_sym
str = '"' * (lpeg.C (1 - lpeg.P '"') ^ 0) * '"' / Atom.make_str
num = (lpeg.R '09', 'AZ') ^ 1 / Atom.make_num
atom = sym + num + str

expr = (lpeg.V 'sexpr') + atom
explist = lpeg.Ct mspace * (lpeg.V 'expr') * (space * atom) ^ 0 * mspace
sexpr = (lpeg.P '(') * (lpeg.V 'explist') * (lpeg.P ')') / Xpr.make_sexpr

nexpr = lpeg.P {
  (lpeg.V 'explist') / Xpr.make_nexpr
  :expr, :explist, :sexpr
}

sexpr = lpeg.P {
  'sexpr'
  :expr, :explist, :sexpr
}

program = nexpr

{
  :space
  :atom
  :expr
  :explist
  :sexpr
  :nexpr
  :program
}
