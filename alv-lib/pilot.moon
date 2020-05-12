import Op, Constant, Input, val, evt from require 'alv.base'
import udp from require 'socket'

local conn

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
  conn or= udp!
  conn\sendto str, '127.0.0.1', 49161

arg = val.num / val.str

play = Constant.meta
  meta:
    name: 'play'
    summary: "Play a note when a bang arrives."
    examples: { '(pilot/play trig ch oct note [vel [len]])' }

  value: class extends Op
    pattern = evt.bang + arg^5
    setup: (inputs) =>
      { trig, args } = pattern\match inputs
      super
        trig: Input.hot trig
        args: [Input.cold a for a in *args]

    tick: =>
      send @unwrap_all!.args

play_ = Constant.meta
  meta:
    name: 'play!'
    summary: "Play a note when a note arrives."
    examples: { '(pilot/play! ch oct note [vel [len]])' }

  value: class extends Op
    pattern = arg + arg + (evt.num / evt.str) + arg^2
    setup: (inputs) =>
      { chan, octv, note, args } = pattern\match inputs
      super
        chan: Input.cold chan
        octv: Input.cold octv
        note: Input.hot note
        args: [Input.cold a for a in *args]

    tick: =>
      { :chan, :octv, :note, :args } = @inputs
      args = for a in *args do a!
      for note in *note!
        send { chan!, octv!, note }, args

effect = Constant.meta
  meta:
    name: 'effect'
    summary: "Set effect parameters."
    examples: { '(pilot/effect which a b)' }
    description: "`effect` should be one of 'DIS', 'CHO', 'REV' or 'FEE'"

  value: class extends Op
    pattern = val.str + arg + arg
    setup: (inputs) =>
      { which, a, b } = pattern\match inputs
      super {
        Input.hot which
        Input.hot a
        Input.hot b
      }

    tick: =>
      send @unwrap_all!

{
  :play
  'play!': play_
  :effect
}
