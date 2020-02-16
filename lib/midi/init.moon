import Stream, Const, Op from require 'core'
import Input, apply_range from require 'lib.midi.core'

dispatch = Input 'system:midi_capture_4'

class gate extends Op
  @doc: "(midi/gate note [chan]) - gate from note-on and note-off messages"

  destroy: =>
    dispatch\detach @mask if @mask

  setup: (note, chan) =>
    dispatch\detach @mask if @mask

    note = note\const!\unwrap 'num'
    chan = chan and chan\const!\unwrap 'num'
    @value = false

    @mask = dispatch\attach { :chan, a: note }, (status) ->
      if status == 'note-on'
        @out\set true
      else if status == 'note-off'
        @out\set false

    @out = Stream 'bool', false
    @out

  update: (dt) => dispatch\tick!

class cc extends Op
  @doc: "(midi/cc cc [chan [range]]) - MIDI CC to number

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- (num) [ 0 - num["

  destroy: =>
    dispatch\detach @mask if @mask

  setup: (cc, chan, @range=Const.str'uni') =>
    dispatch\detach @mask if @mask

    cc = cc\const!\unwrap 'num'
    chan = chan and chan\const!\unwrap 'num'

    @mask = dispatch\attach { status: 'control-change', :chan, a: cc }, (_, _, _, val) ->
      @out\set apply_range @range, val

    @out = Stream 'num', 0
    @out

  update: (dt) => dispatch\tick!

{
  :gate
  :cc
}
