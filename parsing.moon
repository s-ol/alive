import Atom, Xpr from require 'ast'
import R, S, P, V, C, Ct from require 'lpeg'

-- whitespace
wc = S ' \t\r\n'
comment = P {
  'comment',
  expr: (P '(') * ((V 'expr') + (1 - P ')'))^0 * (P ')')
  comment: (P '#(') * ((V 'expr') + (1 - P ')'))^0 * (P ')')
}
space  = (wc^1 * (comment * wc^1)^0) / 1 -- required whitespace
mspace = (comment + wc)^0 / 1            -- optional whitespace

-- atoms
sym = ((R 'az', 'AZ') + (S '-_+*/.!?')) ^ 1 / Atom.make_sym

strd = '"' * (C ((P '\\"') + (P '\\\\') + (1 - P '"'))^0) * '"' / Atom.make_strd
strq = "'" * (C ((P "\\'") + (P '\\\\') + (1 - P "'"))^0) * "'" / Atom.make_strq
str = strd + strq

digit = R '09'
int = digit^1
float = (digit^1 * '.' * digit^0) + (digit^0 * '.' * digit^1)
num = (float + int) / Atom.make_num

atom = num + sym + str

expr = (V 'sexpr') + atom
explist = Ct mspace * (V 'expr') * (space * (V 'expr'))^0 * mspace

tag = (P '[') * num * (P ']')
sexpr = (P '(') * tag^-1 * (V 'explist') * (P ')') / Xpr.make_sexpr

nexpr = P {
  (V 'explist') / Xpr.make_nexpr
  :expr, :explist, :sexpr
}

sexpr = P {
  'sexpr'
  :expr, :explist, :sexpr
}

program = nexpr * -1

{
  :comment
  :space
  :atom
  :expr
  :explist
  :sexpr
  :nexpr
  :program
}
