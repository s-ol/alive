import Constant, Op, Input, T, val, evt from require 'alv.base'
import apply_range, bit from require 'alv-lib.midi.core'
import bor, lshift from bit

color = (r, g) -> bit.bor 12, r, (bit.lshift g, 4)

cc_seq = Constant.meta
  meta:
    name: 'cc-seq'
    summary: "MIDI CC-Sequencer."
    examples: { '(launchctl/cc-seq [port] i start chan [steps [range]])' }
    description: "
returns the value for the i-th step steps (buttons starting from start).
steps defaults to 8.

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

  value: class extends Op
    num = val.num
    pattern = -evt['midi/port'] + num + num + num + -num + -(val.str + num)
    setup: (inputs, scope) =>
      { port, i, start, chan, steps, range } = pattern\match inputs

      super
        port:  Input.hot port or scope\get '*ctrl*'
        i:     Input.hot i
        start: Input.hot start
        chan:  Input.hot chan
        steps: Input.hot steps or Constant.num 8
        range: Input.hot range or Constant.str 'uni'

      @state or= {}
      @out or= T.num\mk_sig apply_range @inputs.range, 0

    tick: =>
      { :port, :i, :start, :chan, :steps, :range } = @inputs

      if steps\dirty!
        while steps! > #@state
          table.insert @state, 0
        while steps! < #@state
          table.remove @state

      curr_i = i! % #@state
      if port\dirty!
        changed = false
        for msg in *port!
          if msg.status == 'control-change' and msg.chan == chan!
            rel_i = msg.a - start!
            if rel_i >= 0 and rel_i < #@state
              @state[rel_i+1] = msg.b
              changed = rel_i == curr_i
        @out\set apply_range range, @state[curr_i+1] if changed
      else
        @out\set apply_range range, @state[curr_i+1]

gate_seq = Constant.meta
  meta:
    name: 'gate-seq'
    summary: "MIDI Gate-Sequencer."
    examples: { '(launchctl/gate-seq [port] i start chan [steps])' }
    description: "
Send `true` or `false` for the `i`-th note-button (MIDI-notes starting from
`start`). `steps` defaults to 8."

  value: class extends Op
    pattern = -evt['midi/port'] + val.num + val.num + val.num + -val.num
    setup: (inputs, scope) =>
      @out or= T.bool\mk_sig!
      @state or= {}
      { port, i, start, chan, steps } = pattern\match inputs

      super
        port:  Input.hot port or scope\get '*ctrl*'
        i:     Input.hot i
        start: Input.hot start
        chan:  Input.hot chan
        steps: Input.hot steps or Constant.num 8

    light = (set, active) ->
      set = if set then 'S' else ' '
      active = if active then 'A' else ' '
      color switch set .. active
        when '  ' then 0, 0
        when ' A' then 1, 1
        when 'S ' then 1, 0
        when 'SA' then 3, 1

    display: (i, active) =>
      start, chan = @inputs.start!, @inputs.chan!
      @inputs.port.stream\send 'note-on', chan, (start + i), light @state[i+1], active

    tick: =>
      { :port, :i, :start, :chan, :steps } = @inputs

      if steps\dirty!
        while steps! > #@state
          table.insert @state, false
        while steps! < #@state
          table.remove @state

      curr_i = i! % #@state

      if port\dirty!
        for msg in *port!
          if msg.status == 'note-on' and msg.chan == chan!
            rel_i = msg.a - start!
            if rel_i >= 0 and rel_i < #@state
              @state[rel_i+1] = not @state[rel_i+1]
              @display rel_i, rel_i == curr_i

      if i\dirty!
        prev_i = (curr_i - 1) % #@state

        @display curr_i, true
        @display prev_i, false

        @out\set @state[curr_i+1]

trig_seq = Constant.meta
  meta:
    name: 'trig-seq'
    summary: "MIDI Trigger-Sequencer."
    examples: { '(launchctl/trig-seq [port] i start chan [steps])' }
    description: "
Send bangs for the `i`-th note-button (MIDI-notes starting from `start`).
`steps` defaults to 8."

  value: class extends Op
    pattern = -evt['midi/port'] + val.num + val.num + val.num + -val.num
    setup: (inputs, scope) =>
      @out or= T.bang\mk_evt!
      @state or= {}
      { port, i, start, chan, steps } = pattern\match inputs

      super
        port:  Input.hot port or scope\get '*ctrl*'
        i:     Input.hot i
        start: Input.hot start
        chan:  Input.hot chan
        steps: Input.hot steps or Constant.num 8

    light = (set, active) ->
      set = if set then 'S' else ' '
      active = if active then 'A' else ' '
      color switch set .. active
        when '  ' then 0, 0
        when ' A' then 1, 1
        when 'S ' then 1, 0
        when 'SA' then 3, 1

    display: (i, active) =>
      start, chan = @inputs.start!, @inputs.chan!
      @inputs.port.stream\send 'note-on', chan, (start + i), light @state[i+1], active

    tick: =>
      { :port, :i, :start, :chan, :steps } = @inputs

      if steps\dirty!
        while steps! > #@state
          table.insert @state, false
        while steps! < #@state
          table.remove @state

      curr_i = i! % #@state

      if port\dirty!
        for msg in *port!
          if msg.status == 'note-on' and msg.chan == chan!
            rel_i = msg.a - start!
            if rel_i >= 0 and rel_i < #@state
              @state[rel_i+1] = not @state[rel_i+1]
              @display rel_i, rel_i == curr_i

      if i\dirty!
        prev_i = (curr_i - 1) % #@state

        @display curr_i, true
        @display prev_i, false

        if @state[curr_i+1]
          @out\add true

{
  'cc-seq': cc_seq
  'gate-seq': gate_seq
  'trig-seq': trig_seq
}
