import Value, Op from require 'core'
import input, output, inout, apply_range from require 'lib.midi.core'

class gate extends Op
  @doc: "(midi/gate port note [chan]) - gate from note-on and note-off messages"

  new: =>
    super 'bool', false

  setup: (params) =>
    super params
    @inputs[3] or= Value.num -1
    @assert_types 'midi/port', 'num', 'num'
    @impulses = { @inputs[1]\unwrap! }

  tick: =>
    local port, note, chan
    { port, note, chan } = [i\unwrap! for i in *@inputs]

    for msg in port\receive!
      if msg.a == note and (chan == -1 or msg.chan == chan)
        if msg.status == 'note-on'
          @out\set true
        elseif msg.status == 'note-off'
          @out\set false

class cc extends Op
  @doc: "(midi/cc port cc [chan [range]]) - MIDI CC to number

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- (num) [ 0 - num["

  new: =>
    super 'num'

  destroy: =>
    dispatch\detach @mask if @mask

  setup: (params) =>
    super params
    @inputs[3] or= Value.num -1
    @inputs[4] or= Value.str 'uni'
    assert #@inputs == 4
    assert @inputs[4].type == 'num' or @inputs[4].type == 'str'
    @assert_types 'midi/port', 'num', 'num'
    @impulses = { @inputs[1]\unwrap! }

    if not @out\unwrap!
      @out\set apply_range @inputs[4], 0

  tick: =>
    local port, cc, chan
    { port, cc, chan } = [i\unwrap! for i in *@inputs]

    for msg in port\receive!
      if msg.status == 'control-change' and
         (chan == -1 or msg.chan == chan) and
         msg.a == cc
        @out\set apply_range @inputs[4], msg.b

{
  :input
  :output
  :inout
  :gate
  :cc
}
