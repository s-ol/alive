----
-- Lpeg Grammar for parsing `alive` code.
--
-- @module parsing
import Constant from require 'alv.result'
import Cell from require 'alv.cell'
import Tag from require 'alv.tag'
import R, S, P, V, C, Ct from require 'lpeg'

-- whitespace
wc = S ' \t\r\n'
comment = P {
  'comment',
  expr: (P '(') * ((V 'expr') + (1 - P ')'))^0 * (P ')')
  comment: (P '#(') * ((V 'expr') + (1 - P ')'))^0 * (P ')')
}
mspace = (comment + wc)^0 / 1            -- optional whitespace
space  = (wc^1 * (comment^0 * wc)^0) / 1 -- required whitespace

-- atoms
digit = R '09'
first = (R 'az', 'AZ') + S '-_+*^%/.,=~!?%$><'
sym = first * (first + digit)^0 / Constant\parse 'sym'

strd = '"' * (C ((P '\\"') + (P '\\\\') + (1 - P '"'))^0) * '"' / Constant\parse 'str', '\"'
strq = "'" * (C ((P "\\'") + (P '\\\\') + (1 - P "'"))^0) * "'" / Constant\parse 'str', '\''
str = strd + strq

int = digit^1
float = (digit^1 * '.' * digit^0) + (digit^0 * '.' * digit^1)
num = ((P '-')^-1 * (float + int)) / Constant\parse 'num'

atom = num + sym + str

expr = (V 'cell') + atom
explist = Ct mspace * ((V 'expr') * (space * (V 'expr'))^0 * mspace)^-1

tag = (P '[') * (digit^1 / Tag.parse) * (P ']')
cell = (P '(') * tag^-1 * (V 'explist') * (P ')') / Cell.parse

root = P {
  (V 'explist') / Cell.parse_root
  :expr, :explist, :cell
}

cell = P {
  'cell'
  :expr, :explist, :cell
}

program = root * -1

--- exports
-- @table exports
-- @tfield pattern comment
-- @tfield pattern space
-- @tfield pattern atom
-- @tfield pattern expr
-- @tfield pattern explist
-- @tfield pattern explist
-- @tfield pattern cell
-- @tfield pattern root
-- @tfield pattern program the main parsing entrypoint
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
