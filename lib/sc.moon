import Op, Value, Scope from require 'core'
import pack from require 'osc'
import dns, udp from require 'socket'

class play extends Op
  @doc: "(sc/play remote synth trigger [name-str val]...) - play a SC SynthDef"

  new: =>
    super!
    @@udp or= udp!

  setup: (params) =>
    super params
    @assert_first_types 'udp/remote', 'str', 'bool'

    assert #@inputs % 2 == 1, "parameters need to be specified as pairs"
    for key in *@inputs[4,,2]
      assert key.type == 'str', "ony strings are supported as control names"
    for val in *@inputs[5,,2]
      assert val.type == 'num', "only numbers are supported as control values"

  tick: =>
    { remote, synth, trig, p } = @inputs

    if trig\dirty! and trig!
      controls = {}
      for i = 4, #@inputs, 2
        table.insert controls, @inputs[i]!
        table.insert controls, @inputs[i+1]!
      msg = pack '/s_new', synth!, -1, 0, 1, unpack controls

      { :ip, :port } = remote!
      @@udp\sendto msg, ip, port

{
  :play
}
