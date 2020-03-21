import Op, Value, Input, Error, match from require 'core.base'
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

play = Value.meta
  meta:
    name: 'play'
    summary: "Play a note when a bang arrives."
    examples: { '(pilot/play trig ch oct note [vel [len]])' }

  value: class extends Op
    setup: (inputs) =>
      { trig, args } = match 'bang *any', inputs
      assert #args < 6, Error 'argument', "too many arguments!"
      super
        trig: Input.event trig
        args: [Input.cold a for a in *args]

    tick: =>
      { :trig, :args } = @inputs
      if trig\dirty! and trig!
        send [a! for a in *@inputs.args]

play_ = Value.meta
  meta:
    name: 'play!'
    summary: "Play a note when a note arrives."
    examples: { '(pilot/play! ch oct note [vel [len]])' }

  value: class extends Op
    setup: (inputs) =>
      { chan, octv, note, args } = match 'any any any *any', inputs
      assert #args < 3, Error 'argument', "too many arguments!"
      super
        chan: Input.cold chan
        octv: Input.cold octv
        note: Input.event note
        args: [Input.cold a for a in *args]

    tick: =>
      if @inputs.note\dirty!
        { :chan, :oct, :note, :args } = @unwrap_all!
        send { chan, oct, note }, args

effect = Value.meta
  meta:
    name: 'effect'
    summary: "Set effect parameters."
    examples: { '(pilot/effect which a b)' }
    description: "`effect` should be one of 'DIS', 'CHO', 'REV' or 'FEE'"

  value: class extends Op
    setup: (inputs) =>
      { which, a, b } = match 'str num num', inputs
      super {
        Input.cold which
        Input.value a
        Input.value b
      }

    tick: =>
      send @unwrap_all!

{
  :play
  'play!': play_
  :effect
}
