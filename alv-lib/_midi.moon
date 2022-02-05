import Constant, T, Array, Struct, Op, Input, T, Error, const from require 'alv.base'
import RtMidiIn, RtMidiOut, RtMidi from require 'luartmidi'

bit = if _VERSION == 'Lua 5.4'
  {
    band: loadstring 'function (a, b) return a & b end'
    bor: loadstring 'function (a, b) return a | b end'
    lshift: loadstring 'function (a, b) return a << b end'
    rshift: loadstring 'function (a, b) return a >> b end'
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

get_port_names = (port) ->
  [port\getportname i for i=1, port\getportcount!]

find_port = (Klass, label, connect) ->
  port = Klass "alv", RtMidi.Api.UNIX_JACK
  names = get_port_names port

  if connect == ''
    port\openvirtualport label
    return port

  -- first exact matches
  for i, name in ipairs names
    if name == connect
      port\openport i, label
      return port, name

  -- then pattern matches
  for i, name in ipairs names
    if name\match connect
      port\openport i
      return port, name

  port\openvirtualport label
  port

class InPort
  new: (@name, connect) =>
    @port, @connect = find_port RtMidiIn, @name, connect
    @msgs = {}

  poll: =>
    @msgs = while true
      delta, bytes = @port\getmessage!
      break unless delta
      { status, a, b } = bytes
      chan = band status, 0xf
      status = MIDI[rshift status, 4]
      { :status, :chan, :a, :b }

  __tostring: => if @connect then "#{@name}@#{@connect}" else @name

class OutPort
  new: (@name, connect) =>
    @port, @connect = find_port RtMidiOut, @name, connect

  send: (status, chan, a, b) =>
    if 'string' == type 'status'
      status = bor (lshift rMIDI[status], 4), chan
    @port\sendmessage status, a, b

  __tostring: => if @connect then "#{@name}@#{@connect}" else @name

class PortOp extends Op
  setup: (inputs) =>
    super inputs

    { :name, :inp, :out } = @inputs

    type = if inp != nil and out != nil
      Struct in: T['midi/in'], out: T['midi/out']
    elseif inp != nil
      T['midi/in']
    elseif out != nil
      T['midi/out']
    else
      error "no port opened"

    @state or= {}
    @setup_out '~', type

  tick: =>
    { :name, :inp, :out } = @unwrap_all!

    if inp and @inputs.inp\dirty!
      @state.inp = InPort name, inp

    if out and @inputs.out\dirty!
      @state.out = OutPort name, out

    @out\set if @state.inp and @state.out
      { 'in': @state.inp, out: @state.out }
    else
      @state.inp or @state.out

port_names = Constant.meta
  meta:
    name: 'port-names'
    summary: "Get all MIDI port names."
    examples: { '(midi/port-names direction)' }
    description: '
`direction` can be either `"in"` or `"out".
Returns an array of strings.'

  value: class extends Op
    setup: (inputs) =>
      dir = const.str\match inputs
      super {}

      dir = dir.result!
      assert dir == "in" or dir == "out", Error 'argument', "'dir' has to be either 'in' or 'out'."

      Klass = if dir == "in" then RtMidiIn else RtMidiOut
      port = Klass "alv", RtMidi.Api.UNIX_JACK
      names = get_port_names port

      Type = Array #names, T.str

      @setup_out '~', Type, names

input = Constant.meta
  meta:
    name: 'input'
    summary: "Create a MIDI input port."
    examples: { '(midi/input name [port])' }
    desciprtion: "
Create a MIDI input port called `name` and optionally connect
it to an existing output `port`.
`name` and `port` are both str= results.
Use [midi/port-names][] to find valid values for `port`.

`port` can either be the exact name of an existing port,
or a [Lua pattern](https://www.lua.org/pil/20.2.html)."

  value: class extends PortOp
    setup: (inputs) =>
      { name, connect } = (const.str * 2)\match inputs
      super
        name: Input.hot name
        inp: Input.hot connect or Constant.str ''

    poll: =>
      @.out!\poll!
      false

output = Constant.meta
  meta:
    name: 'output'
    summary: "Create a MIDI output port."
    examples: { '(midi/output name [port])' }
    desciprtion: "
Create a MIDI output port called `name` and optionally connect
it to an existing input `port`.
`name` and `port` are both str= results.
Use [midi/port-names][] to find valid values for `port`.

`port` can either be the exact name of an existing port,
or a [Lua pattern](https://www.lua.org/pil/20.2.html)."

  value: class extends PortOp
    setup: (inputs) =>
      { name, connect } = (const.str * 2)\match inputs
      super
        name: Input.hot name
        out: Input.hot connect or Constant.str ''

port = Constant.meta
  meta:
    name: 'port'
    summary: "Create a bidirectional MIDI port."
    examples: { '(midi/port name [in] [out])' }
    desciprtion: "
Create a bidirectional MIDI port called `name` and optionally connect
it to the existing output port `in` and input port `out`.

`name`, `in` and `out` are all str= results.
Use [midi/port-names][] to find valid values for `in` and `out`.
`in` and `out` can either be the exact name of an existing port,
or a [Lua pattern](https://www.lua.org/pil/20.2.html)."

  value: class extends PortOp
    setup: (inputs) =>
      { name, inp, out } = (const.str * 3)\match inputs
      super
        name: Input.hot name
        inp: Input.hot inp or Constant.str ''
        out: Input.hot out or Constant.str ''

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
  :port_names
  :apply_range
  :bit
}
