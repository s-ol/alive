import Const from require 'core.const'
import Cell, RootCell from require 'core.cell'
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
sym = ((R 'az', 'AZ') + (S '-_+*/.!?')) ^ 1 / Const\parse 'sym'

strd = '"' * (C ((P '\\"') + (P '\\\\') + (1 - P '"'))^0) * '"' / Const\parse 'str', '\"'
strq = "'" * (C ((P "\\'") + (P '\\\\') + (1 - P "'"))^0) * "'" / Const\parse 'str', '\''
str = strd + strq

digit = R '09'
int = digit^1
float = (digit^1 * '.' * digit^0) + (digit^0 * '.' * digit^1)
num = (float + int) / Const\parse 'num'

atom = num + sym + str

expr = (V 'cell') + atom
explist = Ct mspace * (V 'expr') * (space * (V 'expr'))^0 * mspace

tag = (P '[') * atom * (P ']')
cell = (P '(') * tag^-1 * (V 'explist') * (P ')') / Cell\parse

root = P {
  (V 'explist') / RootCell\parse
  :expr, :explist, :cell
}

cell = P {
  'cell'
  :expr, :explist, :cell
}

program = root * -1

{
  :comment
  :space
  :atom
  :expr
  :explist
  :cell
  :root
  :program
}
