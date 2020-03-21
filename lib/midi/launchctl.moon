import Value, Op, Input, match from require 'core.base'
import apply_range, bit from require 'lib.midi.core'
import bor, lshift from bit

unpack or= table.unpack
color = (r, g) -> bit.bor 12, r, (bit.lshift g, 4)

cc_seq = Value.meta
  meta:
    name: 'cc-seq'
    summary: "MIDI CC-Sequencer."
    examples: { '(launchctl/cc-seq port i start chan [steps [range]])' }
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
    new: => super 'num'

    setup: (inputs) =>
      { port, i, start,
        chan, steps, range } = match 'midi/port num num num num? any?', inputs

      super
        port:  Input.io port
        i:     Input.value i
        start: Input.value start
        chan:  Input.value chan
        steps: Input.value steps or Value.num 8
        range: Input.value range or Value.str 'uni'

      if not @out\unwrap!
        @out\set apply_range @inputs.range, 0

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
        for msg in port!\receive!
          if msg.status == 'control-change' and msg.chan == chan!
            rel_i = msg.a - start!
            if rel_i >= 0 and rel_i < #@state
              @state[rel_i+1] = msg.b
              changed = rel_i == curr_i
        @out\set apply_range range, @state[curr_i+1] if changed
      else
        @out\set apply_range range, @state[curr_i+1]

gate_seq = Value.meta
  meta:
    name: 'gate-seq'
    summary: "MIDI Gate-Sequencer."
    examples: { '(launchctl/gate-seq port i start chan [steps])' }
    description: "
returns `true` or `false` for the `i`-th note-button (MIDI-notes starting from
`start`). `steps` defaults to 8."

  value: class extends Op
    new: =>
      super 'bool', false
      @state = {}

    setup: (inputs) =>
      { port, i, start, chan, steps } = match 'midi/port num num num num?', inputs

      super
        port:  Input.io port
        i:     Input.value i
        start: Input.value start
        chan:  Input.value chan
        steps: Input.value steps or Value.num 8

    light = (set, active) ->
      set = if set then 'S' else ' '
      active = if active then 'A' else ' '
      color switch set .. active
        when '  ' then 0, 0
        when ' A' then 1, 1
        when 'S ' then 1, 0
        when 'SA' then 3, 1

    display: (i, active) =>
      { :port, :start, :chan } = @unwrap_all!
      port\send 'note-on', chan, (start + i), light @state[i+1], active

    tick: =>
      { :port, :i, :start, :chan, :steps } = @inputs

      if steps\dirty!
        while steps! > #@state
          table.insert @state, false
        while steps! < #@state
          table.remove @state

      curr_i = i! % #@state

      if port\dirty!
        for msg in port!\receive!
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

{
  'gate-seq': gate_seq
  'cc-seq': cc_seq
}
