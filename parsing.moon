lpeg = require 'lpeg'
import Atom, Xpr from require 'ast'

space  = (lpeg.S ' \t\r\n') ^ 1 / 1
mspace = (lpeg.S ' \t\r\n') ^ 0 / 1

sym = ((lpeg.R 'az', 'AZ') + (lpeg.S '-_+*')) ^ 1 / Atom.make_sym
str = '"' * (lpeg.C (1 - lpeg.P '"') ^ 0) * '"' / Atom.make_str
num = (lpeg.R '09', 'AZ') ^ 1 / Atom.make_num
atom = sym + num + str

expr = (lpeg.V 'sexpr') + atom
explist = lpeg.Ct mspace * (lpeg.V 'expr') * (space * (lpeg.V 'expr')) ^ 0 * mspace

tag = (lpeg.P '[') * num * (lpeg.P ']')
sexpr = (lpeg.P '(') * tag^-1 * (lpeg.V 'explist') * (lpeg.P ')') / Xpr.make_sexpr

nexpr = lpeg.P {
  (lpeg.V 'explist') / Xpr.make_nexpr
  :expr, :explist, :sexpr
}

sexpr = lpeg.P {
  'sexpr'
  :expr, :explist, :sexpr
}

program = nexpr * -1

{
  :space
  :atom
  :expr
  :explist
  :sexpr
  :nexpr
  :program
}
