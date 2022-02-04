import Constant, Op, Input, T, Struct, sig, evt from require 'alv.base'
import input, output, port, apply_range from require 'alv-lib._midi'
import monotime from require 'system'

gate = Constant.meta
  meta:
    name: 'gate'
    summary: "gate from note-on and note-off messages."
    examples: { '(midi/gate [port] note [chan])' }

  value: class extends Op
    pattern = -sig['midi/in'] + sig.num -sig.num
    setup: (inputs, scope) =>
      { port, note, chan } = pattern\match inputs
      super
        port: Input.cold port or scope\get '*midi*'
        note: Input.hot note
        chan: Input.hot chan or Constant.num -1

        internal: Input.hot T.bool\mk_sig!

      @update_out '~', T.bool

    poll: =>
      { :port, :note, :chan, :internal } = @inputs

      msgs = port!.msgs
      for i = #msgs, 1, -1
        msg = msgs[i]
        if msg.a == note! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'note-on'
            internal.result\set true
            return true
          elseif msg.status == 'note-off'
            internal.result\set false
            return true

      false

    tick: =>
      { :note, :chan, :internal } = @inputs

      if note\dirty! or chan\dirty!
        @out\set false
      elseif internal\dirty!
        @out\set internal!

trig = Constant.meta
  meta:
    name: 'trig'
    summary: "`bang`s from note-on messages."
    examples: { '(midi/trig [port] note [chan])' }

  value: class extends Op
    pattern = -sig['midi/in'] + sig.num -sig.num
    setup: (inputs, scope) =>
      { port, note, chan } = pattern\match inputs
      @out = T.bang\mk_evt!
      super
        port: Input.cold port or scope\get '*midi*'
        note: Input.cold note
        chan: Input.cold chan or Constant.num -1

        internal: Input.hot T.bang\mk_evt!

    poll: =>
      { :port, :note, :chan, :internal } = @inputs

      msgs = port!.msgs
      for i = #msgs, 1, -1
        msg = msgs[i]
        if msg.a == note! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'note-on'
            internal.result\set true
            return true

      false

    tick: =>
      @out\set @inputs.internal!

cc = Constant.meta
  meta:
    name: 'cc'
    summary: "`num` from cc-change messages."
    examples: { '(midi/cc [port] cc [range] [chan])' }
    description: "
`range` can be one of:

- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

  value: class extends Op
    pattern = -sig['midi/in'] + sig.num + -(sig.num / sig.str) + -sig.num
    setup: (inputs, scope) =>
      { port, cc, range, chan } = pattern\match inputs
      super
        port:  Input.cold port or scope\get '*midi*'
        cc:    Input.cold cc
        range: Input.cold range or Constant.str 'uni'
        chan:  Input.cold chan or Constant.num -1

        internal: Input.hot T.bang\mk_evt!

      @state or= 0
      @update_out '~', T.num, apply_range @inputs.range, @state

    poll: =>
      { :port, :cc, :chan, :internal } = @inputs

      msgs = port!.msgs
      for i = #msgs, 1, -1
        msg = msgs[i]
        if msg.a == cc! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'control-change'
            @state = msg.b
            internal.result\set true
            return true

      false

    tick: =>
      { :range, :internal } = @inputs

      if internal!
        @out\set apply_range range, @state

    vis: =>
      {
        type: 'bar'
        bar: @state / 128
      }

send_notes = Constant.meta
  meta:
    name: 'send-notes'
    summary: "`send MIDI note events."
    examples: { '(midi/send-notes [port] [chan] note-events)' }
    description: "
`note-events` is a !-stream of structs with the following keys:

- `pitch`: MIDI pitch (num)
- `dur`: note duration in seconds (num)
- `vel`: MIDI velocity (num, optional)"

  value: class extends Op
    thin = Struct pitch: T.num, dur: T.num
    thiq = Struct pitch: T.num, dur: T.num, vel: T.num
    pattern = -sig['midi/out'] + -sig.num + (evt(thin) / evt(thiq))
    setup: (inputs, scope) =>
      { port, chan, notes } = pattern\match inputs
      @state = {}
      super
        port:  Input.cold port or scope\get '*midi*'
        notes: Input.hot notes
        chan:  Input.cold chan or Constant.num 0

        note_off: Input.hot T.num\mk_evt!

    poll: =>
      time = monotime!

      for pitch, endt in pairs @state
        if endt <= time
          @inputs.note_off.result\set pitch
          return true

      false

    tick: =>
      { :port, :chan, :notes, :note_off } = @unwrap_all!

      if notes
        { :pitch, :dur, :vel } = notes
        pitch = math.floor pitch
        vel = if vel then math.floor vel else 127
        @state[pitch] = monotime! + dur
        port\send 'note-on', chan, pitch, vel

      if pitch = note_off
        @state[pitch] = nil
        port\send 'note-off', chan, pitch, 0

  destroy: =>
    { :port, :chan } = @unwrap_all!

    for pitch, endt in pairs @state
      port\send 'note-off', chan, pitch, 0

Constant.meta
  meta:
    name: 'midi'
    summary: "MIDI integration."

  value:
    :input
    :output
    :port

    :gate
    :trig
    :cc
    'send-notes': send_notes
