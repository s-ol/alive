import Const, Op, FnDef from require 'core'
import dns, udp from require 'socket'

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

  setup: (@trig, @ch, @oct, @note, @vel, @len) =>

  update: (dt) =>
    vals = for c in *{@trig, @ch, @oct, @note, @vel, @len }
      c\update dt
      c\get!

    trig = table.remove vals, 1

    if trig
      send vals

class effect extends Op
  @doc: "(effect which a b) - set an effect

which is one of 'DIS', 'CHO', 'REV' or 'FEE'"

  setup: (@which, @a, @b) =>

  update: (dt) =>
    @which\update dt
    @a\update dt
    @b\update dt
    which, a, b = @which\get!, @a\get!, @b\get!
    if which and a and b
      send { which, a, b }
{
  :play
  :effect
}
