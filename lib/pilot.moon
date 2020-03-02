import Op, EventInput, ValueInput, ColdInput, match from require 'core'
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

send = (...) ->
  str = ''
  for i = 1, select '#', ...
    tbl = select i, ...
    str ..= table.concat [encode v for v in *tbl]
  conn\sendto str, '127.0.0.1', 49161

class play extends Op
  @doc: "(play trig ch oct note [vel [len]]) - play a note when trig is live"

  setup: (inputs) =>
    { trig, args } = match 'bang *any', inputs
    assert #args < 6, "too many arguments!"
    super
      trig: EventInput trig
      args: [ColdInput a for a in *args]

  tick: =>
    { :trig, :args } = @inputs
    if trig\dirty! and trig!
      send [a! for a in *@inputs.args]

class play_ extends Op
  @doc: "(play! ch oct note [vel [len]]) - play a note when note is live"

  setup: (inputs) =>
    { chan, octv, note, args } = match 'any any any *any', inputs
    assert #args < 3, "too many arguments!"
    super
      chan: ColdInput chan
      octv: ColdInput octv
      note: EventInput note
      args: [ColdInput a for a in *args]

  tick: =>
    if @inputs.note\dirty!
      { :chan, :oct, :note, :args } = @unwrap_all!
      send { chan, oct, note }, args

class effect extends Op
  @doc: "(effect which a b) - set an effect

which is one of 'DIS', 'CHO', 'REV' or 'FEE'"

  setup: (inputs) =>
    { which, a, b } = match 'str num num', inputs
    super {
      ColdInput which
      ValueInput a
      ValueInput b
    }

  tick: =>
    send @unwrap_all!
{
  :play
  'play!': play_
  :effect
}
