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

class Input
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

class Output
  new: (name) =>
    @output = RtMidiOut RtMidi.Api.UNIX_JACK

    id = nil
    for port=1,@output\getportcount!
      if name == @output\getportname port
        id = port
        break

    @output\openport id

  send: (status, chan, a, b) =>
    status = bor (lshift rMIDI[status], 4), chan
    @output\sendmessage status, a, b

class InOut
  new: (inp, out) =>
    @inp = Input inp
    @out = Output out

  tick: (...) => @inp\tick ...
  attach: (...) => @inp\attach ...
  detach: (...) => @inp\detach ...
  send: (...) => @out\send ...

{
  :Input
  :Output
  :InOut
}
