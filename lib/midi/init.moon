import Const, Op from require 'core'
import Input from require 'lib.midi.core'

dispatch = Input 'system:midi_capture_6'

class gate extends Op
  @doc: "(midi/gate note [chan]) - gate from note-on and note-off messages"

  new: (...) =>
    super ...

  destroy: =>
    dispatch\detach @mask if @mask

  setup: (note, chan) =>
    dispatch\detach @mask if @mask

    note = note\getc 'num'
    chan = chan and chan\getc 'num'
    @value = false

    @mask = dispatch\attach { :chan, a: note }, (status) ->
      if status == 'note-on'
        @value = true
      else if status == 'note-off'
        @value = false

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

    cc = cc\getc 'num'
    chan = chan and chan\getc 'num'

    @mask = dispatch\attach { status: 'control-change', :chan, a: cc }, (_, _, _, val) -> @apply val

  update: (dt) => dispatch\tick!

  apply: (val) =>
    @value = if @range.type == 'str'
      switch @range\get!
        when 'raw' then val
        when 'uni' then val / 128
        when 'bip' then val / 64 - 1
        when 'rad' then val / 64 * math.pi
        else
          error "unknown range #{@range}"
    elseif @range.type == 'num'
      val / 128 * @range\get!
    else
      error "range has to be a string or number"

{
  :gate
  :cc
}
