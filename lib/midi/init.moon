import Value, Op, ValueInput, IOInput, match from require 'core'
import input, output, inout, apply_range from require 'lib.midi.core'

class gate extends Op
  @doc: "(midi/gate port note [chan]) - gate from note-on and note-off messages"

  new: =>
    super 'bool', false

  setup: (inputs) =>
    { port, note, chan } = match 'midi/port num num?', inputs
    super
      port: IOInput port
      note: ValueInput note
      chan: ValueInput chan or Value.num -1

  tick: =>
    { :port, :note, :chan } = @inputs

    if note\dirty! or chan\dirty!
      @out\set false

    if port\dirty!
      for msg in port!\receive!
        if msg.a == note! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'note-on'
            @out\set true
          elseif msg.status == 'note-off'
            @out\set false

class trig extends Op
  @doc: "(midi/trig port note [chan]) - gate from note-on and note-off messages"

  new: =>
    super 'bang', false

  setup: (inputs) =>
    { port, note, chan } = match 'midi/port num num?', inputs
    super
      port: IOInput port
      note: ValueInput note
      chan: ValueInput chan or Value.num -1

  tick: =>
    { :port, :note, :chan } = @inputs

    if note\dirty! or chan\dirty!
      @out\set false

    if port\dirty!
      for msg in port!\receive!
        if msg.a == note! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'note-on'
            @out\set true


class cc extends Op
  @doc: "(midi/cc port cc [chan [range]]) - MIDI CC to number

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

  new: =>
    super 'num'

  setup: (inputs) =>
    { port, cc, chan, range } = match 'midi/port num num? any?', inputs
    super
      port:  IOInput port
      cc:    ValueInput cc
      chan:  ValueInput chan or Value.num -1
      range: ValueInput range or Value.str 'uni'

    if not @out\unwrap!
      @out\set apply_range @inputs.range, 0

  tick: =>
    { :port, :cc, :chan, :range } = @inputs
    if port\dirty!
      for msg in port!\receive!
        if msg.status == 'control-change' and
           (chan! == -1 or msg.chan == chan!) and
           msg.a == cc!
          @out\set apply_range range, msg.b

{
  :input
  :output
  :inout
  :gate
  :trig
  :cc
}
