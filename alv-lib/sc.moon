import Op, Constant, Input, Array, Struct, T, sig, evt from require 'alv.base'
import new_message, add_item from require 'alv-lib._osc'

unpack or= table.unpack

validate_ctrls = (type) ->
  switch type.__class
    when Array
      assert (type.type == T.num) or (type.type == T.str),
        "synthdef control values have to be either num or str"
    when Struct
      for k, t in pairs type.types
        assert (t == T.num) or (t == T.str),
          "synthdef control value '#{k}' has to be either num or str"

play_ = Constant.meta
  meta:
    name: 'play!'
    summary: 'Play a SuperCollider SynthDef on bangs.'
    examples: { '(play [socket] synth trig ctrls)' }
    description: "
Plays the synth `synth` on the `udp/socket` `socket` whenever `trig` is live.

- `socket` should be a `udp/socket` value. This argument can be omitted and the
  value be passed as a dynamic definition in `*sock*` instead.
- `synth` is the SC synthdef name. It should be a string-value.
- `trig` is the trigger signal. It should be a !-stream of bang-events.
- `ctrls` is a struct of synthdef controls. It should be a ~-stream."
  value: class extends Op
    pattern = -sig['udp/socket'] + sig.str + evt.bang + sig!
    setup: (inputs, scope) =>
      { socket, synth, trig, ctrls } = pattern\match inputs

      validate_ctrls ctrls\type!

      super
        trig:   Input.hot trig
        socket: Input.cold socket or scope\get '*sock*'
        synth:  Input.cold synth
        ctrls:  Input.cold ctrls

    tick: =>
      { :socket, :synth, :ctrls } = @unwrap_all!
      msg = new_message '/s_new'
      msg\add 's', synth
      msg\add 'i', -1
      msg\add 'i', 0
      msg\add 'i', 1
      add_item msg, @inputs.ctrls\type!, ctrls
      socket\send msg.pack msg.content


play = Constant.meta
  meta:
    name: 'play'
    summary: 'Play a SuperCollider SynthDef on events.'
    examples: { '(play [socket] synth ctrls)' }
    description: "
Plays the synth `synth` on the `udp/socket` `socket` whenever an event arrives.

- `socket` should be a `udp/socket` value. This argument can be omitted and the
  value be passed as a dynamic definition in `*sock*` instead.
- `synth` is the SC synthdef name. It should be a string-value.
- `ctrls` is a struct of synthdef controls. It should be a !-stream."
  value: class extends Op
    pattern = -sig['udp/socket'] + sig.str + evt!
    setup: (inputs, scope) =>
      { socket, synth, ctrls } = pattern\match inputs

      validate_ctrls ctrls\type!

      super
        socket: Input.cold socket or scope\get '*sock*'
        synth:  Input.cold synth
        ctrls:  Input.hot ctrls

    tick: =>
      { :socket, :synth, :ctrls } = @unwrap_all!
      msg = new_message '/s_new'
      msg\add 's', synth
      msg\add 'i', -1
      msg\add 'i', 0
      msg\add 'i', 1
      add_item msg, @inputs.ctrls\type!, ctrls
      socket\send msg.pack msg.content

Constant.meta
  meta:
    name: 'sc'
    summary: "SuperCollider integration."

  value:
    :play
    'play!': play_
