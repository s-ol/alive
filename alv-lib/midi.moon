import Constant, Op, Input, T, sig, evt from require 'alv.base'
import input, output, port, apply_range from require 'alv-lib.midi.core'

gate = Constant.meta
  meta:
    name: 'gate'
    summary: "gate from note-on and note-off messages."
    examples: { '(midi/gate [port] note [chan])' }

  value: class extends Op
    pattern = -sig['midi/in'] + sig.num -sig.num
    setup: (inputs, scope) =>
      { port, note, chan } = pattern\match inputs
      @out or= T.bool\mk_sig!
      super
        port: Input.cold port or scope\get '*midi*'
        note: Input.hot note
        chan: Input.hot chan or Constant.num -1

        internal: Input.hot T.bool\mk_sig!

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
      @out or= T.bang\mk_evt!
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
    examples: { '(midi/cc [port] cc [chan [range]])' }
    description: "
`range` can be one of:

- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

  value: class extends Op
    pattern = -sig['midi/in'] + sig.num + -sig.num + -sig.num
    setup: (inputs, scope) =>
      { port, cc, chan, range } = pattern\match inputs
      super
        port:  Input.cold port or scope\get '*midi*'
        cc:    Input.cold cc
        chan:  Input.cold chan or Constant.num -1
        range: Input.cold range or Constant.str 'uni'

        internal: Input.hot T.num\mk_sig 0

      @out or= T.num\mk_sig!

    poll: =>
      { :port, :cc, :chan, :internal } = @inputs

      msgs = port!.msgs
      for i = #msgs, 1, -1
        msg = msgs[i]
        if msg.a == cc! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'control-change'
            internal.result\set msg.b
            return true

      false

    tick: =>
      { :range, :internal } = @inputs

      value = internal!
      @state = value / 128
      @out\set apply_range range, value

    vis: =>
      {
        type: 'bar'
        bar: @state
      }

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
