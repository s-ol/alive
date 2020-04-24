import ValueStream, IOStream, Op, Input, Error, val from require 'alv.base'
import RtMidiIn, RtMidiOut, RtMidi from require 'luartmidi'

bit = do
  ok, bit = pcall require, 'bit32'
  if ok then bit else require 'bit'
import band, bor, lshift, rshift from bit

MIDI = {
  [0x9]: 'note-on'
  [0x8]: 'note-off'

  [0xa]: 'after-key'
  [0xd]: 'after-channel'

  [0xb]: 'control-change'
  [0xe]: 'pitch-bend'
  [0xc]: 'program-change'
}

rMIDI = {v,k for k,v in pairs MIDI}

find_port = (Klass, name) ->
  with Klass RtMidi.Api.UNIX_JACK
    id = nil
    for port=1, \getportcount!
      if name == \getportname port
        id = port
        break

    \openport id

class MidiPort extends IOStream
  new: => super 'midi/port'

  setup: (inp, out) =>
    @inp = inp and find_port RtMidiIn, inp
    @out = out and find_port RtMidiOut, out

  poll: =>
    return unless @inp
    while true
      delta, bytes = @inp\getmessage!
      break unless delta

      { status, a, b } = bytes
      chan = band status, 0xf
      status = MIDI[rshift status, 4]
      @add { :status, :chan, :a, :b }

  send: (status, chan, a, b) =>
    assert @out, Error 'type', "#{@} is not an output or bidirectional port"
    if 'string' == type 'status'
      status = bor (lshift rMIDI[status], 4), chan
    @out\sendmessage status, a, b

class PortOp extends Op
  new: (...) =>
    super ...
    @out or= MidiPort!

  tick: (inp, out) =>
    { :inp, :out } = @unwrap_all!
    @out\setup inp, out

input = ValueStream.meta
  meta:
    name: 'input'
    summary: "Create a MIDI input port."
    examples: { '(midi/input name)' }

  value: class extends PortOp
    setup: (inputs) =>
      name = val.str\match inputs
      super inp: Input.hot name

output = ValueStream.meta
  meta:
    name: 'output'
    summary: "Create a MIDI output port."
    examples: { '(midi/output name)' }

  value: class extends PortOp
    setup: (inputs) =>
      name = val.str\match inputs
      super out: Input.hot name

inout = ValueStream.meta
  meta:
    name: 'inout'
    summary: "Create a bidirectional MIDI port."
    examples: { '(midi/inout name)' }

  value: class extends PortOp
    setup: (inputs) =>
      { inp, out } = (val.str + val.str)\match inputs
      super
        inp: Input.hot inp
        out: Input.hot out

apply_range = (range, val) ->
  if range\type! == 'str'
    switch range!
      when 'raw' then val
      when 'uni' then val / 128
      when 'bip' then val / 64 - 1
      when 'rad' then val / 64 * math.pi
      when 'deg' then val / 128 * 360
      else
        error Error 'argument', "unknown range '#{range!}'"
  elseif range.type == 'num'
    val / 128 * range!
  else
    error Error 'argument', "range has to be a string or number"

{
  :input
  :output
  :inout
  :apply_range
  :bit
}
