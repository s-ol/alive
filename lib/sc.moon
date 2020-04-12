import Op, ValueStream, Input, val, evt from require 'core.base'
import pack from require 'osc'
import dns, udp from require 'socket'

unpack or= table.unpack

play = ValueStream.meta
  meta:
    name: 'play'
    summary: 'Play a SuperCollider SynthDef on bangs.'
    examples: { '(play [socket] synth trig [param val…])' }
    description: "
Plays the synth `synth` on the `udp/socket` `socket` whenever `trig` is live.

- `socket` should be a `udp/socket` value. This argument can be omitted and the
  value be passed as a dynamic definition in `*sock*` instead.
- `synth` is the SC synthdef name. It should be a string-value.
- `trig` is the trigger signal. It should be a stream of bang-events.
- `param` is the name of a synthdef parameter. It should be a string-value."
  value: class extends Op
    pattern = -val['udp/socket'] + val.str + evt.bang + (val.str + val.num)\rep 0
    setup: (inputs, scope) =>
      { socket, synth, trig, ctrls } = pattern\match inputs

      flat_ctrls = {}
      for { key, value } in *ctrls
        table.insert flat_ctrls, key
        table.insert flat_ctrls, value

      super
        trig:   Input.hot trig
        socket: Input.cold socket or scope\get '*sock*'
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
