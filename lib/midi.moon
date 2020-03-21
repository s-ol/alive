import Value, Op, Input, match from require 'core.base'
import input, output, inout, apply_range from require 'lib.midi.core'

gate = Value.meta
  meta:
    name: 'gate'
    summary: "gate from note-on and note-off messages."
    examples: { '(midi/gate port note [chan])' }

  value: class extends Op
    new: =>
      super 'bool', false

    setup: (inputs) =>
      { port, note, chan } = match 'midi/port num num?', inputs
      super
        port: Input.io port
        note: Input.value note
        chan: Input.value chan or Value.num -1

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

trig = Value.meta
  meta:
    name: 'trig'
    summary: "`bang`s from note-on messages."
    examples: { '(midi/trig port note [chan])' }

  value: class extends Op
    new: =>
      super 'bang', false

    setup: (inputs) =>
      { port, note, chan } = match 'midi/port num num?', inputs
      super
        port: Input.io port
        note: Input.value note
        chan: Input.value chan or Value.num -1

    tick: =>
      { :port, :note, :chan } = @inputs

      if note\dirty! or chan\dirty!
        @out\set false

      if port\dirty!
        for msg in port!\receive!
          if msg.a == note! and (chan! == -1 or msg.chan == chan!)
            if msg.status == 'note-on'
              @out\set true

trig = Value.meta
  meta:
    name: 'trig'
    summary: "`num` from cc-change messages."
    examples: { '(midi/cc port cc [chan [range]])' }
    description: "
`range` can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

  value: class extends Op
    new: =>
      super 'num'

    setup: (inputs) =>
      { port, cc, chan, range } = match 'midi/port num num? any?', inputs
      super
        port:  Input.io port
        cc:    Input.value cc
        chan:  Input.value chan or Value.num -1
        range: Input.value range or Value.str 'uni'

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
