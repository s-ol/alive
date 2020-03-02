import Value from require 'core.value'
import Cell, RootCell from require 'core.cell'
import Tag from require 'core.tag'
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
digit = R '09'
first = (R 'az', 'AZ') + S '-_+*/.!?=%'
sym = first * (first + digit)^0 / Value\parse 'sym'

strd = '"' * (C ((P '\\"') + (P '\\\\') + (1 - P '"'))^0) * '"' / Value\parse 'str', '\"'
strq = "'" * (C ((P "\\'") + (P '\\\\') + (1 - P "'"))^0) * "'" / Value\parse 'str', '\''
str = strd + strq

int = digit^1
float = (digit^1 * '.' * digit^0) + (digit^0 * '.' * digit^1)
num = ((P '-')^-1 * (float + int)) / Value\parse 'num'

atom = num + sym + str

expr = (V 'cell') + atom
explist = Ct mspace * (V 'expr') * (space * (V 'expr'))^0 * mspace

tag = (P '[') * (digit^1 / Tag\parse) * (P ']')
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
