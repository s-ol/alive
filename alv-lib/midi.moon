import Constant, Op, Input, T, sig, evt from require 'alv.base'
import input, output, inout, apply_range from require 'alv-lib.midi.core'

gate = Constant.meta
  meta:
    name: 'gate'
    summary: "gate from note-on and note-off messages."
    examples: { '(midi/gate [port] note [chan])' }

  value: class extends Op
    pattern = -evt['midi/port'] + sig.num -sig.num
    setup: (inputs, scope) =>
      @out or= T.bool\mk_sig!
      { port, note, chan } = pattern\match inputs
      super
        port: Input.hot port or scope\get '*midi*'
        note: Input.hot note
        chan: Input.hot chan or Constant.num -1

    tick: =>
      { :port, :note, :chan } = @inputs

      if note\dirty! or chan\dirty!
        @out\set false

      if msg = port!
        if msg.a == note! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'note-on'
            @out\set true
          elseif msg.status == 'note-off'
            @out\set false

trig = Constant.meta
  meta:
    name: 'trig'
    summary: "`bang`s from note-on messages."
    examples: { '(midi/trig [port] note [chan])' }

  value: class extends Op
    pattern = -evt['midi/port'] + sig.num -sig.num
    setup: (inputs, scope) =>
      @out or= T.bang\mk_evt!
      { port, note, chan } = pattern\match inputs
      super
        port: Input.hot port or scope\get '*midi*'
        note: Input.cold note
        chan: Input.cold chan or Constant.num -1

    tick: =>
      { :port, :note, :chan } = @inputs

      if msg = port!
        if msg.a == note! and (chan! == -1 or msg.chan == chan!)
          if msg.status == 'note-on'
            @out\set true

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
    pattern = -evt['midi/port'] + sig.num + -sig.num + -sig.num
    setup: (inputs, scope) =>
      { port, cc, chan, range } = pattern\match inputs
      super
        port:  Input.hot port or scope\get '*midi*'
        cc:    Input.cold cc
        chan:  Input.cold chan or Constant.num -1
        range: Input.cold range or Constant.str 'uni'

      @out or= T.num\mk_sig apply_range @inputs.range, 0

    tick: =>
      { :port, :cc, :chan, :range } = @inputs
      if msg = port!
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
