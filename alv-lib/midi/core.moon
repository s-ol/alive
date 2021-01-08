import Constant, T, Struct, Op, Input, T, Error, const from require 'alv.base'
import RtMidiIn, RtMidiOut, RtMidi from require 'luartmidi'

bit = if _VERSION == 'Lua 5.4'
  {
    band: (a, b) -> a & b
    bor: (a, b) -> a | b
    lshift: (a, b) -> a << b
    rshift: (a, b) -> a >> b
  }
else
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

class InPort
  new: (@name) =>
    @port = find_port RtMidiIn, @name
    @msgs = {}

  poll: =>
    @msgs = while true
      delta, bytes = @port\getmessage!
      break unless delta
      { status, a, b } = bytes
      chan = band status, 0xf
      status = MIDI[rshift status, 4]
      { :status, :chan, :a, :b }

  __tostring: => "[#{@name}]"
  __tojson: => string.format '%q', tostring @

class OutPort
  new: (@name) =>
    @port = find_port RtMidiOut, @name

  send: (status, chan, a, b) =>
    if 'string' == type 'status'
      status = bor (lshift rMIDI[status], 4), chan
    @port\sendmessage status, a, b

  __tostring: => "[#{@name}]"
  __tojson: => string.format '%q', tostring @

class PortOp extends Op
  setup: (inputs) =>
    super inputs
    { :inp, :out } = @unwrap_all!

    if inp and out
      type = Struct in: T['midi/in'], out: T['midi/out']
      @out = type\mk_const { 'in': InPort(inp), out: OutPort(out) }
    elseif inp
      @out = T['midi/in']\mk_const InPort inp
    elseif out
      @out = T['midi/out']\mk_const OutPort out
    else
      error "no port opened"

input = Constant.meta
  meta:
    name: 'input'
    summary: "Create a MIDI input port."
    examples: { '(midi/input name)' }

  value: class extends PortOp
    setup: (inputs) =>
      name = const.str\match inputs
      super inp: Input.hot name

    poll: =>
      @.out!\poll!
      false

output = Constant.meta
  meta:
    name: 'output'
    summary: "Create a MIDI output port."
    examples: { '(midi/output name)' }

  value: class extends PortOp
    setup: (inputs) =>
      name = const.str\match inputs
      super out: Input.hot name

port = Constant.meta
  meta:
    name: 'port'
    summary: "Create a bidirectional MIDI port."
    examples: { '(midi/port name)' }

  value: class extends PortOp
    setup: (inputs) =>
      { inp, out } = (const.str + const.str)\match inputs
      super
        inp: Input.hot inp
        out: Input.hot out

    poll: =>
      @.out!.in\poll!
      false

apply_range = (range, val) ->
  if range\type! == T.str
    switch range!
      when 'raw' then val
      when 'uni' then val / 128
      when 'bip' then val / 64 - 1
      when 'rad' then val / 64 * math.pi
      when 'deg' then val / 128 * 360
      else
        error Error 'argument', "unknown range '#{range!}'"
  elseif range\type! == T.num
    val / 128 * range!
  else
    error Error 'argument', "range has to be a string or number"

{
  :input
  :output
  :port
  :apply_range
  :bit
}
