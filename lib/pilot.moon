import Op from require 'core'
import udp from require 'socket'

conn = udp!
hex = "0123456789abcdef"
encode = (arg) ->
  switch type arg
    when 'number' then
      i = 1 + math.floor arg
      hex\sub i, i
    when 'string' then arg
    else error "invalid type: #{type arg}"

send = (tbl) ->
  str = table.concat [encode v for v in *tbl]
  conn\sendto str, '127.0.0.1', 49161

class play extends Op
  @doc: "(play trig ch oct note [vel [len]]) - play a note when trig is live"

  setup: (@trig, ...) =>
    @vals = { ... }

  update: (dt) =>
    if @trig\unwrap 'bool'
      send [c\unwrap! for c in *@vals]

class effect extends Op
  @doc: "(effect which a b) - set an effect

which is one of 'DIS', 'CHO', 'REV' or 'FEE'"

  setup: (@which, @a, @b) =>

  update: (dt) =>
    which, a, b = (@which\unwrap 'str'), @a\unwrap!, @b\unwrap!
    if which and a and b
      send { which, a, b }
{
  :play
  :effect
}
