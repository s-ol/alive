import IO, Op, Registry, Input, match from require 'core.base'
import RtMidiIn, RtMidiOut, RtMidi from require 'luartmidi'
import band, bor, lshift, rshift from require 'bit32'

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

class MidiPort extends IO
  new: (@inp, @out) =>
    @messages = {}

  tick: =>
    if @inp
      @messages = while true
        delta, bytes = @inp\getmessage!
        break unless delta

        { status, a, b } = bytes
        chan = band status, 0xf
        status = MIDI[rshift status, 4]
        { :status, :chan, :a, :b, port: @ }

  dirty: => #@messages > 0

  receive: =>
    coroutine.wrap ->
      for msg in *@messages
        coroutine.yield msg

  send: (status, chan, a, b) =>
    assert @out, "#{@} is not an output or bidirectional port"
    if 'string' == type 'status'
      status = bor (lshift rMIDI[status], 4), chan
    @out\sendmessage status, a, b

class PortOp extends Op
  new: => super 'midi/port'

  tick: (inp, out) =>
    if (inp and inp\dirty!) or (out and out\dirty!)
      inp = inp and find_port RtMidiIn, inp!
      out = out and find_port RtMidiOut, out!
      @out\set MidiPort inp, out

class input extends PortOp
  @doc: "(midi/input name) - create a MIDI input port"

  setup: (inputs) =>
    { name } = match 'str', inputs
    super name: Input.value name

  tick: => super @inputs.name

class output extends PortOp
  @doc: "(midi/output name) - create a MIDI output port"

  setup: (inputs) =>
    { name } = match 'str', inputs
    super name: Input.value name

  tick: => super nil, @inputs.name

class inout extends PortOp
  @doc: "(midi/inout inname outname) - create a bidirectional MIDI port"

  setup: (inputs) =>
    { inp, out } = match 'str str', inputs
    super
      inp: Input.value inp
      out: Input.value out

  tick: => super @inputs.inp, @inputs.out

apply_range = (range, val) ->
  if range\type! == 'str'
    switch range\unwrap!
      when 'raw' then val
      when 'uni' then val / 128
      when 'bip' then val / 64 - 1
      when 'rad' then val / 64 * math.pi
      when 'deg' then val / 128 * 360
      else
        error "unknown range #{@range}"
  elseif range.type == 'num'
    val / 128 * range\unwrap!
  else
    error "range has to be a string or number"

{
  :input
  :output
  :inout
  :apply_range
}
