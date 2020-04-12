import Op, ValueStream, Input, val, evt from require 'core.base'
import pack from require 'osc'
import dns, udp from require 'socket'

unpack or= table.unpack

play = ValueStream.meta
  meta:
    name: 'play'
    summary: 'Play a SuperCollider SynthDef.'
    examples: { '(play socket synth trig [param val…])' }
    description: "
Plays the synth `synth` on the `udp/socket` `socket` whenever `trig` is live.
Any number of parameter-value pairs can be specified and are captured and sent
together with the note when triggered."
  value: class extends Op
    pattern = val['udp/socket'] + val.str + evt.bang + (val.str + val.num)\rep 0
    setup: (inputs) =>
      { socket, synth, trig, ctrls } = pattern\match inputs

      flat_ctrls = {}
      for { key, value } in *ctrls
        table.insert flat_ctrls, key
        table.insert flat_ctrls, value

      super
        trig:   Input.hot trig
        socket: Input.cold socket
        synth:  Input.cold synth
        ctrls: [Input.cold v for v in *flat_ctrls]

    tick: =>
      if @inputs.trig\dirty! and @inputs.trig!
        { :socket, :synth, :ctrls } = @unwrap_all!
        msg = pack '/s_new', synth, -1, 0, 1, unpack ctrls
        socket\send msg

{
  :play
}
