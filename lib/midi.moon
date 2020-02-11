import Const, Op from require 'core'
import RtMidiIn, RtMidiOut, RtMidi from require 'luartmidi'
import band, rshift from require 'bit32'

MIDI = {
  [0x9]: 'note-on'
  [0x8]: 'note-off'

  [0xa]: 'after-key'
  [0xd]: 'after-channel'

  [0xb]: 'control-change'
  [0xe]: 'pitch-bend'
  [0xc]: 'program-change'
}

class Dispatcher
  new: (name) =>
    @input = RtMidiIn RtMidi.Api.UNIX_JACK

    id = nil
    for port=1,@input\getportcount!
      if name == @input\getportname port
        id = port
        break

    @input\openport id

    @listeners = {}

  tick: =>
    while true
      delta, bytes = @input\getmessage!
      break unless delta

      { status, a, b } = bytes
      chan = band status, 0xf
      status = MIDI[rshift status, 4]
      @dispatch status, chan, a, b

  dispatch: (status, chan, a, b) =>
    L\trace "dispatching MIDI event #{status} CH#{chan} #{a} #{b}"
    for mask, handler in pairs @listeners
      match = true
      match and= status == mask.status if mask.status
      match and= chan == mask.chan if mask.chan
      match and= a == mask.a if mask.a
      if match
        handler status, chan, a, b

  -- register a handler
  -- mask is { :status, :chan, :a } (all keys optional)
  attach: (mask, handler) =>
    @listeners[mask] = handler

  detach: (mask) =>
    @listeners[mask] = nil

dispatch = Dispatcher 'system:midi_capture_2'

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
