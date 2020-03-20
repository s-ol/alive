import Op, Input, Error, match from require 'core.base'
import pack from require 'osc'
import dns, udp from require 'socket'

class play extends Op
  @doc: "(sc/play socket synth trigger [name-str val]...) - play a SC SynthDef"

  setup: (inputs) =>
    { socket, synth, trig, ctrls } = match 'udp/socket str bang *any?', inputs

    assert #ctrls % 2 == 0, Error 'argument', "parameters need to be specified as pairs"
    for key in *ctrls[1,,2]
      assert key\type! == 'str', Error 'argument', "ony strings are supported as control names"
    for val in *ctrls[2,,2]
      assert val\type! == 'num', Error 'argument', "only numbers are supported as control values"

    super
      trig:   Input.event trig
      socket: Input.cold socket
      synth:  Input.cold synth
      ctrls: [Input.cold v for v in *ctrls]

  tick: =>
    if @inputs.trig\dirty! and @inputs.trig!
      { :socket, :synth, :ctrls } = @unwrap_all!
      msg = pack '/s_new', synth, -1, 0, 1, unpack ctrls
      socket\send msg

{
  :play
}
